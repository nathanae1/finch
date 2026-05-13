import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import '../../relay/services/relay_storage_service.dart';
import '../../services/clock.dart';

/// `POST /media/<hash>` (Relay mode) — Owner pushes an encrypted media
/// blob for the Relay to serve to Followers.
///
/// The URL carries the BLAKE2b-256 plaintext hash; the body carries the
/// already-encrypted bytes (`nonce(24) || XChaCha20-Poly1305(...)`).
/// The Relay never decrypts — verifying that the body's hash matches
/// the URL would require the plaintext, which the Relay can't see, so
/// this handler trusts the Owner-signed URL/body pair as authenticated
/// by [ownerSignatureMiddleware].
///
/// Mounted **behind** [ownerSignatureMiddleware]; by the time it runs,
/// the body is authenticated as the Owner's. Idempotent on the hash —
/// the Owner can push the same blob more than once without harm.
///
/// Returns 202 on success, 400 on missing hash, 507 on storage cap
/// (currently a placeholder — Plan 15b enforces the cap).
Handler relayMediaPushHandler({
  required RelayMediaStore mediaStore,
  required Clock clock,
}) {
  return (Request request) async {
    final hash = request.url.pathSegments.isNotEmpty
        ? request.url.pathSegments.last
        : null;
    if (hash == null || hash.isEmpty) {
      return Response(400, body: 'missing media hash');
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
    }
    final bodyBytes = builder.toBytes();
    if (bodyBytes.isEmpty) {
      return Response(400, body: 'empty body');
    }

    await mediaStore.putMedia(
      hash: hash,
      bytes: bodyBytes,
      createdAt: clock.nowUnixSeconds(),
    );

    return Response(202, body: '');
  };
}
