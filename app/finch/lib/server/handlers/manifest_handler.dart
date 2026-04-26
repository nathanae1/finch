import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:shelf/shelf.dart';

import '../../services/storage_service.dart';
import '../../services/types.dart';

/// `GET /manifest?since={ts}&until={ts}` — lightweight CBOR list of
/// `{id, created_at}` for the owner's events in the requested range,
/// ordered newest-first (the underlying DAO's order).
///
/// `has_older` means "more events exist beyond the returned window at the
/// older end." Callers iterate by setting `until = oldest.createdAt - 1`
/// on the next request.
Handler manifestHandler({
  required StorageService storage,
  required Future<Identity?> Function() identityLookup,
  int pageLimit = 1000,
}) {
  return (Request request) async {
    final identity = await identityLookup();
    if (identity == null) {
      return Response(503, body: 'not ready');
    }
    final params = request.url.queryParameters;
    final since = _parseInt(params['since']);
    final until = _parseInt(params['until']);
    if (params.containsKey('since') && since == null) {
      return Response(400, body: 'invalid since');
    }
    if (params.containsKey('until') && until == null) {
      return Response(400, body: 'invalid until');
    }
    final fetched = await storage.getEvents(
      pubkey: identity.pubkey,
      since: since,
      until: until,
      limit: pageLimit + 1,
    );
    final hasOlder = fetched.length > pageLimit;
    final events = hasOlder ? fetched.sublist(0, pageLimit) : fetched;
    final body = Uint8List.fromList(
      cbor.encode(<String, dynamic>{
        'pubkey': identity.pubkey,
        'events': events
            .map((e) => <String, dynamic>{
                  'id': e.id,
                  'created_at': e.createdAt,
                })
            .toList(),
        'has_older': hasOlder,
      }),
    );
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
