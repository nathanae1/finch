import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../models/protocol_version.dart';
import '../../services/storage_service.dart';
import '../../services/types.dart';

/// `GET /status` — JSON view of who this server speaks for, what protocol
/// version it implements, and rough storage stats. No auth.
Handler statusHandler({
  required StorageService storage,
  required Future<Identity?> Function() identityLookup,
}) {
  return (Request request) async {
    final identity = await identityLookup();
    if (identity == null) {
      return Response(503, body: 'not ready');
    }
    final ownEvents = await storage.getEvents(pubkey: identity.pubkey);
    final mediaUsed = await storage.getMediaCacheSize();
    final body = jsonEncode({
      'pubkey': identity.pubkey,
      'version': kStarlingProtocolVersion,
      'event_count': ownEvents.length,
      'media_storage_used': mediaUsed,
    });
    return Response.ok(
      body,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  };
}
