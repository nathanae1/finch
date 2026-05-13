import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../models/protocol_version.dart';
import '../../relay/services/relay_storage_service.dart';
import '../../services/storage/daos/relay_dao.dart';

/// `GET /status` (Relay mode) — returns the same shape as the social
/// `/status` so Followers can reuse their existing reachability probe
/// (`PeerReachabilityMonitor`) unchanged.
///
/// `pubkey` is the paired Owner's pubkey (or empty pre-pair); a
/// Follower that finds this matches the pubkey in their `Follow` row
/// promotes the Relay endpoint to "reachable."
Handler relayStatusHandler({
  required RelayDao dao,
  required RelayMediaStore mediaStore,
}) {
  return (Request request) async {
    final owner = await dao.getPairedOwner();
    final eventCount = await dao.servedEventCount();
    final mediaBytes = await mediaStore.totalBytes();
    final body = jsonEncode(<String, dynamic>{
      'pubkey': owner?.pubkey ?? '',
      'version': kFinchProtocolVersion,
      'media_storage_used': mediaBytes,
      'event_count': eventCount,
    });
    return Response.ok(
      body,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  };
}
