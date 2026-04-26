import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:shelf/shelf.dart';

import '../../services/clock.dart';
import '../../services/storage_service.dart';
import '../../services/types.dart';

/// `POST /follow-request` — accepts a CBOR-encoded follow request and
/// stores it for the owner to act on. Body shape:
///
/// ```
/// {
///   requester_pubkey: string,
///   encrypted_return_endpoints: bytes,
///   nonce: bytes (24),
///   timestamp: int,           // requester's send time, used by both
///                             // sides to derive the same shared key
/// }
/// ```
///
/// The body-size middleware caps reads at 1 MB. The raw bytes are stored
/// verbatim — Plan 08's accept flow decrypts the exact bytes the requester
/// sent.
Handler followRequestHandler({
  required StorageService storage,
  required Clock clock,
}) {
  return (Request request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
    }
    final bodyBytes = builder.toBytes();
    final Map<dynamic, dynamic> decoded;
    try {
      final raw = cbor.decode(bodyBytes);
      if (raw is! Map) {
        return Response(400, body: 'invalid body');
      }
      decoded = raw;
    } catch (_) {
      return Response(400, body: 'invalid cbor');
    }
    final requesterPubkey = decoded['requester_pubkey'];
    final endpoints = decoded['encrypted_return_endpoints'];
    final nonce = decoded['nonce'];
    final timestamp = decoded['timestamp'];
    if (requesterPubkey is! String ||
        !_isBytes(endpoints) ||
        !_isBytes(nonce) ||
        timestamp is! int) {
      return Response(400, body: 'invalid body');
    }
    await storage.saveInboundRequest(
      FollowRequest(
        pubkey: requesterPubkey,
        payload: bodyBytes,
        createdAt: clock.nowUnixSeconds(),
        requestTimestamp: timestamp,
      ),
    );
    return Response(202, body: '');
  };
}

bool _isBytes(dynamic value) => value is Uint8List || value is List<int>;
