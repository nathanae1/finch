import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import '../../services/crypto/crockford_base32.dart';
import '../../services/crypto_service.dart';

/// Middleware that authenticates owner-only writes to a Relay.
///
/// Verifies the `X-Finch-Pubkey` + `X-Finch-Sig` header pair against
/// `blake2b_256(request_body)`, then checks the recovered pubkey matches
/// the paired Owner. Reads the body once, verifies, and re-injects it
/// so the inner handler doesn't have to.
///
/// Status codes:
/// - 401 if headers are missing, malformed, or the signature doesn't
///   validate against the claimed pubkey
/// - 403 if the signature is valid but the pubkey isn't the Relay's
///   paired Owner (or no Owner is paired yet)
///
/// The middleware is constructed with an async [getOwnerPubkey] closure
/// rather than a static value so the middleware survives `/pair` and
/// "Unpair" without re-installing. A `null` return means "no Owner
/// paired" and translates to 403.
///
/// The Owner pubkey in the DB is Crockford-base32 (matches the rest of
/// the codebase); on the wire it's base64. The middleware decodes both
/// to raw bytes and compares.
Middleware ownerSignatureMiddleware({
  required CryptoService crypto,
  required Future<String?> Function() getOwnerPubkey,
}) {
  return (Handler inner) {
    return (Request request) async {
      final pubkeyHeader = request.headers['x-finch-pubkey'];
      final sigHeader = request.headers['x-finch-sig'];
      if (pubkeyHeader == null || sigHeader == null) {
        return Response(401, body: 'missing auth headers');
      }

      final Uint8List pubkeyBytes;
      final Uint8List sigBytes;
      try {
        pubkeyBytes = base64.decode(pubkeyHeader);
        sigBytes = base64.decode(sigHeader);
      } catch (_) {
        return Response(401, body: 'invalid base64 in auth headers');
      }

      // Buffer the body so we can hash it AND let the inner handler
      // read it. Shelf request bodies are one-shot streams; we have to
      // re-inject after consuming.
      final builder = BytesBuilder(copy: false);
      await for (final chunk in request.read()) {
        builder.add(chunk);
      }
      final bodyBytes = builder.toBytes();

      final digest = crypto.blake2b256(bodyBytes);
      if (!crypto.verify(pubkeyBytes, digest, sigBytes)) {
        return Response(401, body: 'invalid signature');
      }

      final ownerPubkey = await getOwnerPubkey();
      if (ownerPubkey == null) {
        return Response(403, body: 'relay is not paired');
      }
      final Uint8List ownerBytes;
      try {
        ownerBytes = crockfordBase32Decode(ownerPubkey);
      } catch (_) {
        // DB row is malformed — treat as not paired rather than 500.
        return Response(403, body: 'relay owner unrecognized');
      }
      if (!_bytesEqual(pubkeyBytes, ownerBytes)) {
        return Response(403, body: 'pubkey is not relay owner');
      }

      final downstream = request.change(body: bodyBytes);
      return inner(downstream);
    };
  };
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
