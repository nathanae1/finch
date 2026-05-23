import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:shelf/shelf.dart';

import '../../services/follow_service.dart';

/// `POST /follow-accept` — receives the responder's wrapped feed key after
/// they accept a follow request we sent. Body shape (CBOR):
///
/// ```
/// {
///   owner_pubkey: string,        // responder's pubkey (target of original
///                                // /follow-request)
///   encrypted_feed_key: bytes,   // ciphertext (no nonce prefix)
///   nonce: bytes (24),
///   epoch: int,                  // owner's current feed_key_epoch
///   timestamp: int,              // echoes original request timestamp so
///                                // both sides derive the same shared key
/// }
/// ```
///
/// Delegates the heavy lifting to [FollowService.ingestFollowAccept], which
/// looks up the matching outbound row, derives the shared key, decrypts the
/// feed key, writes the follows row, and deletes the outbound row.
Handler followAcceptHandler({required FollowService followService}) {
  return (Request request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
    }
    final Map<dynamic, dynamic> decoded;
    try {
      final raw = cbor.decode(builder.toBytes());
      if (raw is! Map) {
        return Response(400, body: 'invalid body');
      }
      decoded = raw;
    } catch (_) {
      return Response(400, body: 'invalid cbor');
    }
    final ownerPubkey = decoded['owner_pubkey'];
    final encryptedFeedKey = decoded['encrypted_feed_key'];
    final nonce = decoded['nonce'];
    final epoch = decoded['epoch'];
    final timestamp = decoded['timestamp'];
    if (ownerPubkey is! String ||
        !_isBytes(encryptedFeedKey) ||
        !_isBytes(nonce) ||
        epoch is! int ||
        timestamp is! int) {
      return Response(400, body: 'invalid body');
    }
    try {
      await followService.ingestFollowAccept(
        ownerPubkey: ownerPubkey,
        encryptedFeedKey: _asBytes(encryptedFeedKey),
        nonce: _asBytes(nonce),
        epoch: epoch,
        timestamp: timestamp,
      );
      return Response(202, body: '');
    } on FollowFailure catch (e) {
      switch (e.kind) {
        case FollowFailureKind.unknownRequester:
          return Response(404, body: 'unknown owner');
        case FollowFailureKind.decryptFailed:
          return Response(400, body: 'decryption failed');
        case FollowFailureKind.network:
        case FollowFailureKind.noEndpoints:
          return Response(500, body: 'internal error');
      }
    }
  };
}

bool _isBytes(dynamic value) => value is Uint8List || value is List<int>;

Uint8List _asBytes(dynamic value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  throw StateError('expected bytes, got ${value.runtimeType}');
}
