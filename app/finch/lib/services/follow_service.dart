import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:http/http.dart' as http;

import '../models/connection_card.dart';
import 'clock.dart';
import 'crypto/crockford_base32.dart';
import 'crypto/key_cache.dart';
import 'crypto_service.dart';
import 'storage_service.dart';
import 'types.dart';

/// Why we couldn't fulfill the request — surfaces to the UI for inline error
/// display and to the retry pump for status transitions.
enum FollowFailureKind { noEndpoints, network, unknownRequester, decryptFailed }

class FollowFailure implements Exception {
  const FollowFailure(this.kind, this.message);
  final FollowFailureKind kind;
  final String message;

  @override
  String toString() => 'FollowFailure($kind): $message';
}

/// Outcome of the synchronous send leg of [FollowService.acceptFollowRequest].
/// `delivered` means the responder POSTed and got 202; `queued` means delivery
/// failed and the encoded body was enqueued for the retry pump.
enum AcceptDelivery { delivered, queued, failed }

/// Result type for the round-trip ingest of an inbound `/follow-accept`.
/// Used by the server handler to choose its response code.
class IngestAcceptResult {
  const IngestAcceptResult({required this.follow});
  final Follow follow;
}

/// Hand-off transport used for tests. The default implementation wraps
/// [http.Client]; tests inject a deterministic version that routes
/// requests directly into the other peer's storage.
class HandshakeTransport {
  HandshakeTransport(this._client);
  final http.Client _client;

  Future<int> postFollowRequest(String baseUrl, Uint8List body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/follow-request'),
      headers: const {'content-type': 'application/cbor'},
      body: body,
    );
    return res.statusCode;
  }

  Future<int> postFollowAccept(String baseUrl, Uint8List body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/follow-accept'),
      headers: const {'content-type': 'application/cbor'},
      body: body,
    );
    return res.statusCode;
  }
}

/// Coordinates the follow-request handshake (Plan 08).
///
/// Wire shapes:
/// - `POST /follow-request` body (CBOR):
///   `{ requester_pubkey, encrypted_return_endpoints, nonce, timestamp }`
///   Plaintext of `encrypted_return_endpoints` (CBOR):
///   `{ connection_card, feed_key_epoch }` — connection card is the
///   requester's contact info, feed_key_epoch is informational.
/// - `POST /follow-accept` body (CBOR):
///   `{ owner_pubkey, encrypted_feed_key, nonce, epoch, timestamp }`
///   Plaintext of `encrypted_feed_key` is the raw 32-byte feed key.
///
/// Shared key derivation uses `crypto.deriveSharedKey(myXSk, theirXPk,
/// requesterEdPk, responderEdPk, timestamp)` with `timestamp` echoed
/// verbatim through the handshake so both sides agree on it.
///
/// Semantics: a single QR-scan handshake is one-directional. Alice scans
/// Bob's QR → Alice gets Bob's feed key. Bob does NOT automatically gain
/// Alice's feed key; Bob would need to scan Alice's QR for that.
class FollowService {
  FollowService({
    required CryptoService crypto,
    required StorageService storage,
    required Clock clock,
    required HandshakeTransport transport,
    required Future<Identity?> Function() identityLookup,
    required Future<Uint8List?> Function() ownSecretKeyLookup,
    required Future<List<Endpoint>> Function() ownEndpointsLookup,
    FeedKeyCache? feedKeyCache,
  })  : _crypto = crypto,
        _storage = storage,
        _clock = clock,
        _transport = transport,
        _identityLookup = identityLookup,
        _ownSecretKeyLookup = ownSecretKeyLookup,
        _ownEndpointsLookup = ownEndpointsLookup,
        _feedKeyCache = feedKeyCache;

  final CryptoService _crypto;
  final StorageService _storage;
  final Clock _clock;
  final HandshakeTransport _transport;
  final Future<Identity?> Function() _identityLookup;
  final Future<Uint8List?> Function() _ownSecretKeyLookup;
  final Future<List<Endpoint>> Function() _ownEndpointsLookup;
  final FeedKeyCache? _feedKeyCache;

  // --- Outbound: send a follow request ---

  Future<void> sendFollowRequest(ConnectionCard target) async {
    final identity = await _requireIdentity();
    final secretKey = await _requireSecretKey();
    final ownEndpoints = await _ownEndpointsLookup();
    final endpoint = _firstEndpoint(target.endpoints);

    final timestamp = _clock.nowUnixSeconds();
    final myEdPk = crockfordBase32Decode(identity.pubkey);
    final theirEdPk = crockfordBase32Decode(target.pubkey);
    final myXSk = _crypto.ed25519ToX25519SecretKey(secretKey);
    final theirXPk = _crypto.ed25519ToX25519PublicKey(theirEdPk);

    final sharedKey = _crypto.deriveSharedKey(
      myXSk,
      theirXPk,
      myEdPk,
      theirEdPk,
      timestamp,
    );

    final ownCard = ConnectionCard(
      pubkey: identity.pubkey,
      endpoints: ownEndpoints,
    );
    final innerCbor = Uint8List.fromList(cbor.encode(<String, dynamic>{
      'connection_card': ownCard.toMap(),
      'feed_key_epoch': identity.feedKeyEpoch,
    }));
    final nonce = _crypto.randomBytes(24);
    final ciphertext = _crypto.encrypt(innerCbor, nonce, sharedKey);

    final body = Uint8List.fromList(cbor.encode(<String, dynamic>{
      'requester_pubkey': identity.pubkey,
      'encrypted_return_endpoints': ciphertext,
      'nonce': nonce,
      'timestamp': timestamp,
    }));

    final int status;
    try {
      status = await _transport.postFollowRequest(
        _baseUrlFor(endpoint),
        body,
      );
    } catch (e) {
      throw FollowFailure(FollowFailureKind.network, 'send failed: $e');
    }
    if (status != 202) {
      throw FollowFailure(
        FollowFailureKind.network,
        'unexpected response: $status',
      );
    }

    await _storage.saveOutboundRequest(
      FollowRequest(
        pubkey: target.pubkey,
        payload: target.toBytes(),
        createdAt: timestamp,
        requestTimestamp: timestamp,
      ),
    );
  }

  // --- Inbound: accept a pending request ---

  /// Returns the delivery result so the UI can render the outbound state
  /// ("Sent" vs "Pending — retrying").
  Future<AcceptDelivery> acceptFollowRequest(String requesterPubkey) async {
    final identity = await _requireIdentity();
    final secretKey = await _requireSecretKey();
    final inbound = await _storage.getInboundRequest(requesterPubkey);
    if (inbound == null) {
      throw FollowFailure(
        FollowFailureKind.unknownRequester,
        'no pending request from $requesterPubkey',
      );
    }
    final outer = _decodeMap(inbound.payload);
    final inner =
        _decryptInner(outer, identity, secretKey, inbound.requestTimestamp);

    final requesterCard = ConnectionCard.fromMap(
      inner['connection_card'] as Map<dynamic, dynamic>,
    );
    final endpoint = _firstEndpoint(requesterCard.endpoints);

    final acceptBody = _buildAcceptBody(
      identity: identity,
      secretKey: secretKey,
      requesterCard: requesterCard,
      timestamp: inbound.requestTimestamp,
    );

    var delivery = AcceptDelivery.delivered;
    try {
      final status = await _transport.postFollowAccept(
        _baseUrlFor(endpoint),
        acceptBody,
      );
      if (status != 202) {
        delivery = AcceptDelivery.queued;
      }
    } catch (_) {
      delivery = AcceptDelivery.queued;
    }

    if (delivery == AcceptDelivery.queued) {
      await _storage.enqueue(
        requesterPubkey,
        _wrapQueueEntry('${_baseUrlFor(endpoint)}/follow-accept', acceptBody),
      );
      await _storage.updateInboundRequestStatus(
        requesterPubkey,
        'pending-send',
      );
    } else {
      await _storage.updateInboundRequestStatus(
        requesterPubkey,
        'accepted',
      );
    }
    return delivery;
  }

  Uint8List _wrapQueueEntry(String url, Uint8List body) =>
      Uint8List.fromList(cbor.encode(<String, dynamic>{
        'url': url,
        'body': body,
      }));

  // --- Inbound: reject a pending request ---

  Future<void> rejectFollowRequest(String requesterPubkey) =>
      _storage.deleteInboundRequest(requesterPubkey);

  // --- Inbound /follow-accept handler entry point ---

  Future<IngestAcceptResult> ingestFollowAccept({
    required String ownerPubkey,
    required Uint8List encryptedFeedKey,
    required Uint8List nonce,
    required int epoch,
    required int timestamp,
  }) async {
    final identity = await _requireIdentity();
    final secretKey = await _requireSecretKey();

    final outbound = await _storage.getOutboundRequest(ownerPubkey);
    if (outbound == null) {
      throw FollowFailure(
        FollowFailureKind.unknownRequester,
        'no outbound request to $ownerPubkey',
      );
    }
    if (outbound.requestTimestamp != timestamp) {
      throw const FollowFailure(
        FollowFailureKind.decryptFailed,
        'timestamp mismatch with stored outbound request',
      );
    }

    final myEdPk = crockfordBase32Decode(identity.pubkey);
    final theirEdPk = crockfordBase32Decode(ownerPubkey);
    final myXSk = _crypto.ed25519ToX25519SecretKey(secretKey);
    final theirXPk = _crypto.ed25519ToX25519PublicKey(theirEdPk);
    final sharedKey = _crypto.deriveSharedKey(
      myXSk,
      theirXPk,
      myEdPk,
      theirEdPk,
      timestamp,
    );

    final Uint8List feedKey;
    try {
      feedKey = _crypto.decrypt(encryptedFeedKey, nonce, sharedKey);
    } catch (e) {
      throw FollowFailure(
        FollowFailureKind.decryptFailed,
        'feed key decryption failed: $e',
      );
    }

    final card = ConnectionCard.fromBytes(outbound.payload);
    final follow = Follow(
      pubkey: ownerPubkey,
      connectionCard: card.toMap().toString(),
      feedKey: feedKey,
      feedKeyEpoch: epoch,
      lastSyncedAt: _clock.nowUnixSeconds(),
    );
    await _storage.saveFollow(follow);
    await _storage.deleteOutboundRequest(ownerPubkey);
    _feedKeyCache?.put(ownerPubkey, feedKey, epoch);

    return IngestAcceptResult(follow: follow);
  }

  // --- Unfollow ---

  Future<void> unfollow(String pubkey) async {
    await _storage.removeFollow(pubkey);
    _feedKeyCache?.remove(pubkey);
  }

  // --- Retry pump entry point ---

  /// Drains queued accept-payloads. Each queued entry is CBOR
  /// `{ url, body }` where `body` is the encrypted /follow-accept payload.
  /// On success: removes the queue entry and marks the inbound row
  /// 'accepted'. On failure: increments retryCount and (past [maxRetries])
  /// marks the inbound row 'send-failed' and removes the entry.
  Future<void> retryQueuedAccepts({int maxRetries = 10}) async {
    final pendingSend =
        await _storage.getInboundRequestsByStatus('pending-send');
    for (final inbound in pendingSend) {
      final entries = await _storage.dequeue(inbound.pubkey);
      for (final entry in entries) {
        final wrapped = _decodeMap(entry.eventBlob);
        final url = wrapped['url'] as String;
        final body = _asBytes(wrapped['body']);

        var success = false;
        try {
          final status =
              await _transport.postFollowAccept(_stripAcceptSuffix(url), body);
          success = status == 202;
        } catch (_) {
          success = false;
        }

        if (success) {
          await _storage.removeFromQueue(entry.id);
          await _storage.updateInboundRequestStatus(
            inbound.pubkey,
            'accepted',
          );
        } else {
          await _storage.incrementRetry(entry.id);
          if (entry.retryCount + 1 >= maxRetries) {
            await _storage.updateInboundRequestStatus(
              inbound.pubkey,
              'send-failed',
            );
            await _storage.removeFromQueue(entry.id);
          }
        }
      }
    }
  }

  String _stripAcceptSuffix(String url) {
    const suffix = '/follow-accept';
    if (url.endsWith(suffix)) return url.substring(0, url.length - suffix.length);
    return url;
  }

  Future<Identity> _requireIdentity() async {
    final identity = await _identityLookup();
    if (identity == null) {
      throw const FollowFailure(
        FollowFailureKind.unknownRequester,
        'no identity loaded',
      );
    }
    return identity;
  }

  Future<Uint8List> _requireSecretKey() async {
    final sk = await _ownSecretKeyLookup();
    if (sk == null) {
      throw const FollowFailure(
        FollowFailureKind.unknownRequester,
        'no secret key loaded',
      );
    }
    return sk;
  }

  Endpoint _firstEndpoint(List<Endpoint> endpoints) {
    if (endpoints.isEmpty) {
      throw const FollowFailure(
        FollowFailureKind.noEndpoints,
        'no reachable endpoints',
      );
    }
    // Preference order: onion, relay, direct/lan-direct, then anything else.
    Endpoint? pick;
    for (final type in ['onion', 'relay', 'direct', 'lan-direct']) {
      pick = endpoints.firstWhere(
        (e) => e.type == type,
        orElse: () => const Endpoint(type: '', address: ''),
      );
      if (pick.type.isNotEmpty) return pick;
    }
    return endpoints.first;
  }

  String _baseUrlFor(Endpoint endpoint) {
    final addr = endpoint.address;
    if (addr.startsWith('http://') || addr.startsWith('https://')) return addr;
    return 'http://$addr';
  }

  Map<dynamic, dynamic> _decodeMap(Uint8List bytes) {
    final decoded = cbor.decode(bytes);
    if (decoded is! Map) {
      throw const FollowFailure(
        FollowFailureKind.decryptFailed,
        'expected CBOR map',
      );
    }
    return decoded;
  }

  Map<dynamic, dynamic> _decryptInner(
    Map<dynamic, dynamic> outer,
    Identity identity,
    Uint8List secretKey,
    int timestamp,
  ) {
    final ct = _asBytes(outer['encrypted_return_endpoints']);
    final nonce = _asBytes(outer['nonce']);
    final requesterPk = outer['requester_pubkey'] as String;

    final myEdPk = crockfordBase32Decode(identity.pubkey);
    final theirEdPk = crockfordBase32Decode(requesterPk);
    final myXSk = _crypto.ed25519ToX25519SecretKey(secretKey);
    final theirXPk = _crypto.ed25519ToX25519PublicKey(theirEdPk);
    final sharedKey = _crypto.deriveSharedKey(
      myXSk,
      theirXPk,
      theirEdPk,
      myEdPk,
      timestamp,
    );

    final Uint8List plaintext;
    try {
      plaintext = _crypto.decrypt(ct, nonce, sharedKey);
    } catch (e) {
      throw FollowFailure(
        FollowFailureKind.decryptFailed,
        'return-endpoints decryption failed: $e',
      );
    }
    return _decodeMap(plaintext);
  }

  Uint8List _buildAcceptBody({
    required Identity identity,
    required Uint8List secretKey,
    required ConnectionCard requesterCard,
    required int timestamp,
  }) {
    final myEdPk = crockfordBase32Decode(identity.pubkey);
    final theirEdPk = crockfordBase32Decode(requesterCard.pubkey);
    final myXSk = _crypto.ed25519ToX25519SecretKey(secretKey);
    final theirXPk = _crypto.ed25519ToX25519PublicKey(theirEdPk);
    final sharedKey = _crypto.deriveSharedKey(
      myXSk,
      theirXPk,
      theirEdPk,
      myEdPk,
      timestamp,
    );
    final nonce = _crypto.randomBytes(24);
    final ct = _crypto.encrypt(identity.feedKey, nonce, sharedKey);
    return Uint8List.fromList(cbor.encode(<String, dynamic>{
      'owner_pubkey': identity.pubkey,
      'encrypted_feed_key': ct,
      'nonce': nonce,
      'epoch': identity.feedKeyEpoch,
      'timestamp': timestamp,
    }));
  }

  Uint8List _asBytes(dynamic value) {
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    throw FollowFailure(
      FollowFailureKind.decryptFailed,
      'expected bytes, got ${value.runtimeType}',
    );
  }
}
