import 'package:shelf/shelf.dart';

import '../../models/envelope.dart';
import '../../models/protocol_version.dart';
import '../../services/storage/daos/relay_dao.dart';

/// `GET /events?since={ts}` (Relay mode).
///
/// Returns an `Envelope` of `EnvelopeItem(type:'event', payload: bytes)`
/// where each payload is raw `EncryptedEvent` CBOR. Matches the
/// social-mode contract so existing Follower-side sync code
/// (`SyncEngine`, `events_handler`'s callers) decrypts and verifies the
/// items unchanged.
///
/// The Relay echoes the bytes verbatim — it never decrypted, never
/// re-encrypted, and never advanced any `msgSeq`. The author-time
/// `msgSeq` baked into each `EncryptedEvent` is what the Follower's
/// `ContentKeyService` will use to derive per-message AEAD keys for
/// the inner content + media.
Handler relayEventsHandler({
  required RelayDao dao,
  int pageLimit = 500,
}) {
  return (Request request) async {
    final params = request.url.queryParameters;
    int? since;
    if (params.containsKey('since')) {
      since = int.tryParse(params['since']!);
      if (since == null) {
        return Response(400, body: 'invalid since');
      }
    }

    final rows = await dao.servedEventsSince(since ?? 0);
    final capped = rows.length > pageLimit ? rows.sublist(0, pageLimit) : rows;

    final items = capped
        .map((e) => EnvelopeItem(type: 'event', payload: e.payload))
        .toList();
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
