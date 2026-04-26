import 'dart:developer' as developer;

import '../models/envelope.dart';
import '../models/protocol_version.dart';
import '../services/storage_service.dart';
import '../services/types.dart';
import 'sync_engine.dart';

/// Per-peer drop threshold. After 3 failed deliveries, remove the entry —
/// the peer has likely unfollowed or is permanently unreachable. Match
/// Plan 10's retry policy.
const int kOutboundMaxRetries = 3;

/// Drain queued events targeting [follow], pushing them in a single
/// envelope to [peer] via [transport.pushEvents]. Called by `SyncEngine`
/// at the tail of each peer's sync slot, after manifest+envelope pull.
///
/// On success: every queue row removed. On failure: each row's
/// `retry_count` is incremented; rows that reach `kOutboundMaxRetries`
/// are dropped. Counts as a single batch — partial-success is not modeled
/// because the receiver's POST /events is all-or-nothing per request.
Future<OutboundDrainResult> drainOutboundQueueForPeer({
  required StorageService storage,
  required SyncTransport transport,
  required Follow follow,
  required PeerConnection peer,
}) async {
  final queued = await storage.dequeue(follow.pubkey);
  if (queued.isEmpty) {
    return const OutboundDrainResult(pushed: 0, dropped: 0, retried: 0);
  }

  final envelope = Envelope(
    version: kFinchProtocolVersion,
    items: queued
        .map((q) => EnvelopeItem(type: 'event', payload: q.eventBlob))
        .toList(growable: false),
  );

  try {
    await transport.pushEnvelope(peer, envelope);
    for (final entry in queued) {
      await storage.removeFromQueue(entry.id);
    }
    return OutboundDrainResult(
      pushed: queued.length,
      dropped: 0,
      retried: 0,
    );
  } catch (e) {
    developer.log(
      'pushEvents failed for ${follow.pubkey}: $e',
      name: 'outbound_drain',
    );
    var dropped = 0;
    var retried = 0;
    for (final entry in queued) {
      if (entry.retryCount + 1 >= kOutboundMaxRetries) {
        await storage.removeFromQueue(entry.id);
        dropped++;
        developer.log(
          'dropped after $kOutboundMaxRetries retries: '
          'queue id=${entry.id} target=${entry.targetPubkey}',
          name: 'outbound_drain',
        );
      } else {
        await storage.incrementRetry(entry.id);
        retried++;
      }
    }
    return OutboundDrainResult(
      pushed: 0,
      dropped: dropped,
      retried: retried,
    );
  }
}

class OutboundDrainResult {
  const OutboundDrainResult({
    required this.pushed,
    required this.dropped,
    required this.retried,
  });
  final int pushed;
  final int dropped;
  final int retried;
}
