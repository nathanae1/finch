import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/simple.dart';

import '../../services/clock.dart';
import '../../services/crypto/crockford_base32.dart';
import '../../services/crypto_service.dart';
import '../../services/storage/daos/relay_dao.dart';

/// Token lifetime for the QR pairing handshake. The Owner has ten
/// minutes to scan the QR and complete the `/pair` round-trip before
/// the Relay generates a fresh token.
const pairingTokenTtl = Duration(minutes: 10);

/// Domain-separation tag for the signed pairing claim. Bound into
/// `blake2b_256("finch-relay-pair-v1" || owner_pubkey || relay_onion ||
/// pairing_token)` so a token captured for one Relay can't be redirected
/// to another.
const _pairingClaimTag = 'finch-relay-pair-v1';

/// Pre-pair Relay state. The pairing screen renders a QR from
/// [PairingTokenState] until [PairingService.consumeClaim] returns a
/// successful [PairingOutcome.success]; the dashboard reads
/// [RelayPairedOwner].
class PairingTokenState {
  const PairingTokenState({
    required this.token,
    required this.expiresAt,
  });

  /// 32-byte random token. Constant-time-compared inside
  /// [PairingService.consumeClaim].
  final Uint8List token;

  /// Wall-clock unix-seconds at which the token expires.
  final int expiresAt;
}

enum PairingOutcome {
  /// Successful claim. Owner pubkey is persisted; the dashboard takes over.
  success,

  /// Token has already been claimed once. 409 on the wire.
  tokenAlreadyConsumed,

  /// Token expired without being claimed. 410 on the wire.
  tokenExpired,

  /// Token bytes don't match the active pairing token. 401.
  tokenMismatch,

  /// Signature didn't verify against [PairingClaim.ownerPubkey]. 401.
  signatureInvalid,

  /// Caller bypassed `writePairingToken` so there's no active token. 410.
  noActiveToken,
}

/// Decoded `/pair` request body. The Relay binds the claim to its own
/// `.onion` address itself — the wire does NOT carry `relay_onion`,
/// because a captured token bound to a different Relay must not
/// successfully redirect pairing here.
class PairingClaim {
  const PairingClaim({
    required this.ownerPubkey,
    required this.pairingToken,
    required this.sig,
  });

  /// Owner's Ed25519 public key, base64-encoded as on the wire
  /// (`X-Finch-Pubkey` style). Persisted in Crockford base32 after a
  /// successful claim — see [PairingService._pubkeyToText].
  final String ownerPubkey;

  /// 32-byte token bytes the phone read from the QR.
  final Uint8List pairingToken;

  /// Ed25519 sig over `blake2b_256(tag || owner_pubkey_bytes ||
  /// relay_onion_bytes || pairing_token)`. The Relay reconstructs the
  /// hashed input from its own onion address — the value is not in the
  /// wire body.
  final Uint8List sig;

  /// Decode a `/pair` request body. Throws [FormatException] on
  /// malformed CBOR or missing fields.
  factory PairingClaim.fromCbor(Uint8List body) {
    final raw = cbor.decode(body);
    if (raw is! Map) {
      throw const FormatException('pairing claim is not a CBOR map');
    }
    final pk = raw['owner_pubkey'];
    final token = raw['pairing_token'];
    final sig = raw['sig'];
    if (pk is! String || token is! List || sig is! List) {
      throw const FormatException('pairing claim is missing fields');
    }
    return PairingClaim(
      ownerPubkey: pk,
      pairingToken: Uint8List.fromList(token.cast<int>()),
      sig: Uint8List.fromList(sig.cast<int>()),
    );
  }
}

class PairingService {
  PairingService({
    required RelayDao dao,
    required CryptoService crypto,
    required Clock clock,
    required String Function() relayOnion,
  })  : _dao = dao,
        _crypto = crypto,
        _clock = clock,
        _relayOnion = relayOnion;

  final RelayDao _dao;
  final CryptoService _crypto;
  final Clock _clock;
  final String Function() _relayOnion;

  /// Build the signed-claim bytes both sides hash before signing /
  /// verifying. Centralized so the phone-side initiator and the Relay
  /// stay in lockstep.
  static Uint8List buildClaimBytes({
    required Uint8List ownerPubkey,
    required String relayOnion,
    required Uint8List pairingToken,
  }) {
    final builder = BytesBuilder(copy: false)
      ..add(utf8.encode(_pairingClaimTag))
      ..add(ownerPubkey)
      ..add(utf8.encode(relayOnion))
      ..add(pairingToken);
    return builder.toBytes();
  }

  /// Generate and persist a fresh pairing token. Discards any prior
  /// token. Returns the new state for the pairing screen.
  Future<PairingTokenState> issueToken() async {
    final token = _crypto.randomBytes(32);
    final now = _clock.nowUnixSeconds();
    final expiresAt = now + pairingTokenTtl.inSeconds;
    await _dao.writePairingToken(
      token: token,
      createdAt: now,
      expiresAt: expiresAt,
    );
    return PairingTokenState(token: token, expiresAt: expiresAt);
  }

  /// Return the active token state if there is one and it hasn't
  /// expired; otherwise null. The pairing screen calls this on resume
  /// to decide whether to render the existing QR or issue a fresh one.
  Future<PairingTokenState?> currentToken() async {
    final row = await _dao.getActivePairingToken();
    if (row == null) return null;
    if (row.consumedAt != null) return null;
    if (row.expiresAt <= _clock.nowUnixSeconds()) return null;
    return PairingTokenState(token: row.token, expiresAt: row.expiresAt);
  }

  /// Validate and consume a `/pair` claim from the phone. On success
  /// writes `relay_paired_owner` and marks the token consumed.
  Future<PairingOutcome> consumeClaim(PairingClaim claim) async {
    final row = await _dao.getActivePairingToken();
    if (row == null) return PairingOutcome.noActiveToken;

    final now = _clock.nowUnixSeconds();
    if (row.consumedAt != null) return PairingOutcome.tokenAlreadyConsumed;
    if (row.expiresAt <= now) return PairingOutcome.tokenExpired;
    if (!_constantTimeEqual(row.token, claim.pairingToken)) {
      return PairingOutcome.tokenMismatch;
    }

    final Uint8List ownerPubkeyBytes;
    try {
      ownerPubkeyBytes = base64.decode(claim.ownerPubkey);
    } catch (_) {
      return PairingOutcome.signatureInvalid;
    }

    final claimBytes = buildClaimBytes(
      ownerPubkey: ownerPubkeyBytes,
      relayOnion: _relayOnion(),
      pairingToken: claim.pairingToken,
    );
    final digest = _crypto.blake2b256(claimBytes);
    if (!_crypto.verify(ownerPubkeyBytes, digest, claim.sig)) {
      return PairingOutcome.signatureInvalid;
    }

    await _dao.setPairedOwner(_pubkeyToText(ownerPubkeyBytes), now);
    await _dao.markTokenConsumed(row.token, now);
    return PairingOutcome.success;
  }

  /// Convert raw 32-byte Ed25519 pubkey to the codebase-canonical
  /// Crockford base32 text form. The DB stores pubkeys this way; the
  /// signature middleware decodes both header and DB value to bytes
  /// before comparing.
  String _pubkeyToText(Uint8List bytes) => crockfordBase32Encode(bytes);

  /// Stable identifier the Relay returns in the `/pair` response so the
  /// phone can label this Relay in its UI without storing the Owner's
  /// pubkey on the relay side. Computed as
  /// `blake2b_256(owner_pubkey_bytes || relay_onion_bytes)`, hex-encoded.
  /// Re-pairing the same Owner against the same Relay yields the same
  /// id; either side changing produces a fresh id.
  Future<String> computeRelayId(String ownerPubkeyBase64) async {
    final ownerBytes = base64.decode(ownerPubkeyBase64);
    final input = BytesBuilder(copy: false)
      ..add(ownerBytes)
      ..add(utf8.encode(_relayOnion()));
    final digest = _crypto.blake2b256(input.toBytes());
    final hex = StringBuffer();
    for (final b in digest) {
      hex.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }

  bool _constantTimeEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
