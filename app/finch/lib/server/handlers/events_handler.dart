import 'package:shelf/shelf.dart';

import '../../models/envelope.dart';
import '../../models/protocol_version.dart';
import '../../services/content_key_service.dart';
import '../../services/storage_service.dart';
import '../../services/types.dart';

/// `GET /events?since={ts}` — CBOR `Envelope` of `EnvelopeItem(type:'event')`,
/// each wrapping a freshly re-encrypted `EncryptedEvent`.
///
/// Returns:
///   1. The owner's own events (kind=1 posts, kind=4 outgoing comments,
///      kind=5 likes, kind=6 deletes/unlikes).
///   2. Events from others whose `ref` points to one of the owner's events
///      (received comments / likes / tombstones on own posts, pushed via
///      `POST /events` from followers — see Plan 10 re-distribution).
///
/// All items are re-encrypted with the owner's current
/// `identity.feedKey` / `feedKeyEpoch`. The receiver derives the event id
/// from the inner signed `Event`, so the wire-level pubkey on the
/// re-encrypted envelope item may be a third party's pubkey (when we're
/// re-distributing their comment); the inner Ed25519 signature is what
/// the syncing peer verifies.
Handler eventsHandler({
  required StorageService storage,
  required ContentKeyService contentKey,
  required Future<Identity?> Function() identityLookup,
  int pageLimit = 500,
}) {
  return (Request request) async {
    final identity = await identityLookup();
    if (identity == null) {
      return Response(503, body: 'not ready');
    }
    final params = request.url.queryParameters;
    int? since;
    if (params.containsKey('since')) {
      since = int.tryParse(params['since']!);
      if (since == null) {
        return Response(400, body: 'invalid since');
      }
    }
    final events = await storage.getOwnAndIncomingRefs(
      identity.pubkey,
      since: since,
      limit: pageLimit,
    );
    final items = events.map((event) {
      final encrypted = contentKey.encryptEvent(
        event,
        identity.feedKey,
        identity.feedKeyEpoch,
      );
      return EnvelopeItem(type: 'event', payload: encrypted.toBytes());
    }).toList();
    final envelope = Envelope(
      version: kFinchProtocolVersion,
      items: items,
    );
    return Response.ok(
      envelope.toBytes(),
      headers: const {'content-type': 'application/cbor'},
    );
  };
}
