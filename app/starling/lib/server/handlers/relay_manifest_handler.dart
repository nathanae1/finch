import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:shelf/shelf.dart';

import '../../services/storage/daos/relay_dao.dart';

/// `GET /manifest?since={ts}&until={ts}` (Relay mode).
///
/// Returns the same wire shape as the social `/manifest`:
///   `{ pubkey, events: [{ id, created_at }], has_older }`
///
/// `id` is the plaintext Event id the Owner stamped at push time —
/// see [ServedEventEntries]. The Follower diffs this against its local
/// store and fetches the missing rows via `/events`.
///
/// Relay-mode manifest does NOT carry the `new_feed_key` or
/// `connection_card_update` extensions — those originate on the Owner's
/// phone, not on the Relay. The Owner distributes them on their own
/// `/manifest`.
Handler relayManifestHandler({
  required RelayDao dao,
  int pageLimit = 1000,
}) {
  return (Request request) async {
    final params = request.url.queryParameters;
    final since = _parseInt(params['since']);
    final until = _parseInt(params['until']);
    if (params.containsKey('since') && since == null) {
      return Response(400, body: 'invalid since');
    }
    if (params.containsKey('until') && until == null) {
      return Response(400, body: 'invalid until');
    }

    final owner = await dao.getPairedOwner();
    if (owner == null) {
      return Response(503, body: 'relay not paired');
    }

    final events = await dao.manifestRows(
      since: since,
      until: until,
      limit: pageLimit + 1,
    );
    final hasOlder = events.length > pageLimit;
    final page = hasOlder ? events.sublist(0, pageLimit) : events;

    final body = Uint8List.fromList(cbor.encode(<String, dynamic>{
      'pubkey': owner.pubkey,
      'events': page
          .map((e) => <String, dynamic>{
                'id': e.id,
                'created_at': e.createdAt,
              })
          .toList(),
      'has_older': hasOlder,
    }));
    return Response.ok(
      body,
      headers: const {'content-type': 'application/cbor'},
    );
  };
}

int? _parseInt(String? raw) {
  if (raw == null) return null;
  return int.tryParse(raw);
}
