import 'dart:developer' as developer;
import 'dart:typed_data';

import '../models/models.dart';
import '../services/clock.dart';
import '../services/content_key_service.dart';
import '../services/storage_service.dart';
import '../services/types.dart';
import 'concurrency.dart';
import 'manifest_exchange.dart';
import 'outbound_drain.dart';
import 'peer_connection_factory.dart';

/// The narrow surface the sync engine needs from a transport. Implemented
/// by `LanNetworkService` for v1; Plans 11/15 will add Tor/relay-backed
/// implementations behind the same shape.
abstract class SyncTransport {
  Future<Manifest> fetchManifest(
    PeerConnection peer, {
    int? since,
    int? until,
  });

  Future<Envelope> fetchEnvelope(PeerConnection peer, {int? since});

  Future<Uint8List> fetchMedia(PeerConnection peer, String hash);

  /// Push an envelope of events to the peer (Plan 10 outbound queue).
  /// On success the receiver returns 202; transport-level failures throw.
  Future<void> pushEnvelope(PeerConnection peer, Envelope envelope);
}

/// One-call orchestration for "pull what's new from every reachable
/// follow." Mirrors the spec in `app/plans/09-lan-sync.md`:
///
///   for each followed pubkey:
///     resolve LAN peer (Plan 11/15 add Tor + relay)
///     manifest exchange (diff against local event IDs)
///     fetch missing events
///     decrypt + verify (per-item integrity, untrusted envelope)
///     store with is_own=0
///     update last_synced_at
///
/// Concurrency is bounded by [Pool] (default 5).
class SyncEngine {
  SyncEngine({
    required StorageService storage,
    required ContentKeyService contentKey,
    required SyncTransport transport,
    required PeerConnectionFactory peerFactory,
    required Clock clock,
    int maxParallelPeers = 5,
  })  : _storage = storage,
        _contentKey = contentKey,
        _transport = transport,
        _peerFactory = peerFactory,
        _clock = clock,
        _pool = Pool(maxParallelPeers);

  final StorageService _storage;
  final ContentKeyService _contentKey;
  final SyncTransport _transport;
  final PeerConnectionFactory _peerFactory;
  final Clock _clock;
  final Pool _pool;

  /// Runs one sync pass. Returns a per-peer report so the UI can surface
  /// "syncing… 3/5 done" or "Bob unreachable."
  Future<SyncReport> syncNow() async {
    final follows = await _storage.getFollows();
    if (follows.isEmpty) {
      return SyncReport(
        startedAt: _clock.nowUnixSeconds(),
        finishedAt: _clock.nowUnixSeconds(),
        peers: const [],
      );
    }

    final startedAt = _clock.nowUnixSeconds();
    final results = await Future.wait(
      follows.map((follow) => _pool.run(() => _syncOnePeer(follow))),
    );
    return SyncReport(
      startedAt: startedAt,
      finishedAt: _clock.nowUnixSeconds(),
      peers: results,
    );
  }

  Future<PeerSyncReport> _syncOnePeer(Follow follow) async {
    final connection = _peerFactory.buildLanConnection(follow.pubkey);
    if (connection == null) {
      return PeerSyncReport(
        pubkey: follow.pubkey,
        status: PeerSyncStatus.unreachable,
      );
    }

    final exchange =
        ManifestExchange(transport: _transport, storage: _storage);
    final ManifestDiff diff;
    try {
      diff = await exchange.fetchAndDiff(connection, follow);
    } catch (e) {
      developer.log(
        'manifest fetch failed for ${follow.pubkey}: $e',
        name: 'sync_engine',
      );
      return PeerSyncReport(
        pubkey: follow.pubkey,
        status: PeerSyncStatus.unreachable,
        error: e.toString(),
      );
    }

    if (diff.missingIds.isEmpty) {
      // Nothing to fetch — but we still advance last_synced_at so the next
      // window is anchored at "now." That requires we at least heard back
      // from the peer, which we did. Drain the outbound queue so queued
      // comments/likes don't sit waiting just because no inbound work
      // was due.
      await _storage.updateLastSynced(follow.pubkey, _clock.nowUnixSeconds());
      final drain = await drainOutboundQueueForPeer(
        storage: _storage,
        transport: _transport,
        follow: follow,
        peer: connection,
      );
      return PeerSyncReport(
        pubkey: follow.pubkey,
        status: PeerSyncStatus.upToDate,
        eventsPushed: drain.pushed,
        eventsPushDropped: drain.dropped,
      );
    }

    final Envelope envelope;
    try {
      envelope = await _transport.fetchEnvelope(
        connection,
        since: diff.windowSince,
      );
    } catch (e) {
      developer.log(
        'envelope fetch failed for ${follow.pubkey}: $e',
        name: 'sync_engine',
      );
      return PeerSyncReport(
        pubkey: follow.pubkey,
        status: PeerSyncStatus.unreachable,
        error: e.toString(),
      );
    }

    var inserted = 0;
    var skipped = 0;
    var unknownPreserved = 0;
    final receivedAt = _clock.nowUnixSeconds();

    for (final item in envelope.items) {
      if (item.type == 'event') {
        final ok = await _processEventItem(item, follow);
        if (ok) {
          inserted++;
        } else {
          skipped++;
        }
      } else {
        await _storage.saveUnknownEnvelopeItem(
          UnknownEnvelopeItem(
            sourcePubkey: follow.pubkey,
            envelopeVersion: envelope.version,
            type: item.type,
            payload: item.payload,
            extensions: null,
            receivedAt: receivedAt,
          ),
        );
        unknownPreserved++;
      }
    }

    await _storage.updateLastSynced(follow.pubkey, _clock.nowUnixSeconds());

    final drain = await drainOutboundQueueForPeer(
      storage: _storage,
      transport: _transport,
      follow: follow,
      peer: connection,
    );

    return PeerSyncReport(
      pubkey: follow.pubkey,
      status: PeerSyncStatus.synced,
      eventsFetched: inserted,
      eventsSkipped: skipped,
      unknownItemsPreserved: unknownPreserved,
      eventsPushed: drain.pushed,
      eventsPushDropped: drain.dropped,
    );
  }

  /// Processes one envelope item of `type:"event"`. Returns true if the
  /// event was decrypted, verified, and stored; false if it was rejected.
  ///
  /// Authorization: the encrypted-blob's claimed `pubkey` may either be
  /// the source we follow (the source's own event) or a third party's
  /// pubkey (a re-distributed comment/like/tombstone the source received
  /// via `POST /events`). For the third-party case we require the inner
  /// `Event.ref` to anchor to a known event from the source or our own
  /// — otherwise a misbehaving source could ship arbitrary signed events
  /// claiming any ref. The inner Ed25519 signature is always verified
  /// inside `decryptEvent`.
  Future<bool> _processEventItem(EnvelopeItem item, Follow follow) async {
    final EncryptedEvent encrypted;
    try {
      encrypted = EncryptedEvent.fromBytes(item.payload);
    } catch (e) {
      developer.log(
        'malformed EncryptedEvent from ${follow.pubkey}: $e',
        name: 'sync_engine',
      );
      return false;
    }

    final Event plain;
    try {
      plain = _contentKey.decryptEvent(encrypted, follow.feedKey);
    } catch (e) {
      developer.log(
        'decrypt/verify failed for ${follow.pubkey}: $e',
        name: 'sync_engine',
      );
      return false;
    }

    if (plain.pubkey != follow.pubkey) {
      // Re-distributed event (e.g. a comment from a third party that
      // landed on the source's device). Anchor it: ref must point to a
      // local event whose author is the source we're syncing from, or
      // ourselves. Otherwise drop.
      if (plain.ref == null) {
        developer.log(
          'rejected re-distributed event without ref from '
          '${follow.pubkey}: pubkey=${plain.pubkey}',
          name: 'sync_engine',
        );
        return false;
      }
      final anchor = await _storage.getEvent(plain.ref!);
      if (anchor == null) {
        developer.log(
          'rejected re-distributed event with unknown ref from '
          '${follow.pubkey}: ref=${plain.ref}',
          name: 'sync_engine',
        );
        return false;
      }
      final identity = await _storage.getIdentity();
      final selfPubkey = identity?.pubkey;
      final ok = anchor.pubkey == follow.pubkey || anchor.pubkey == selfPubkey;
      if (!ok) {
        developer.log(
          'rejected re-distributed event whose ref does not anchor to '
          'source or self from ${follow.pubkey}: '
          'anchor.pubkey=${anchor.pubkey}',
          name: 'sync_engine',
        );
        return false;
      }
    }

    try {
      await _storage.saveEvent(plain);
    } catch (e) {
      developer.log(
        'save failed for event ${plain.id}: $e',
        name: 'sync_engine',
      );
      return false;
    }
    return true;
  }
}

/// Aggregate report for one [SyncEngine.syncNow] call.
class SyncReport {
  const SyncReport({
    required this.startedAt,
    required this.finishedAt,
    required this.peers,
  });
  final int startedAt;
  final int finishedAt;
  final List<PeerSyncReport> peers;

  bool get hadFailures => peers.any((p) => p.status == PeerSyncStatus.unreachable);
  int get totalEventsFetched =>
      peers.fold(0, (sum, p) => sum + p.eventsFetched);
}

/// Per-follow result for one sync pass.
class PeerSyncReport {
  const PeerSyncReport({
    required this.pubkey,
    required this.status,
    this.eventsFetched = 0,
    this.eventsSkipped = 0,
    this.unknownItemsPreserved = 0,
    this.eventsPushed = 0,
    this.eventsPushDropped = 0,
    this.error,
  });
  final String pubkey;
  final PeerSyncStatus status;
  final int eventsFetched;
  final int eventsSkipped;
  final int unknownItemsPreserved;
  final int eventsPushed;
  final int eventsPushDropped;
  final String? error;
}

enum PeerSyncStatus {
  /// Peer responded; new events fetched and stored.
  synced,

  /// Peer responded; we already had everything in the window.
  upToDate,

  /// Couldn't reach the peer (no LAN entry, HTTP failure, timeout).
  unreachable,
}
