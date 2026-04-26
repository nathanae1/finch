import 'package:shelf/shelf.dart';

import '../../models/envelope.dart';
import '../../models/protocol_version.dart';
import '../../services/content_key_service.dart';
import '../../services/storage_service.dart';
import '../../services/types.dart';

/// `GET /events?since={ts}` — CBOR `Envelope` of `EnvelopeItem(type:'event')`,
/// each wrapping a freshly re-encrypted `EncryptedEvent` for the owner's
/// posts in the range.
///
/// Re-encryption uses the current `identity.feedKey` / `feedKeyEpoch`. The
/// receiver derives the event id from the inner signed `Event`, so a fresh
/// per-request nonce is fine. Plan 13 will replace this with a timestamp-
/// keyed historical lookup once feed-key rotation lands.
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
    final events = await storage.getEvents(
      pubkey: identity.pubkey,
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
