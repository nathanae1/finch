import 'dart:async';
import 'dart:typed_data';

import '../../models/models.dart';
import '../storage_service.dart';
import '../types.dart';

/// In-memory mock StorageService for testing without a database.
class MockStorageService implements StorageService {
  Identity? _identity;
  final Map<String, Follow> _follows = {};
  final Map<String, Event> _events = {};
  final Map<String, CachedMedia> _mediaCache = {};
  final List<FollowRequest> _inboundRequests = [];
  final List<FollowRequest> _outboundRequests = [];
  final List<QueuedEvent> _queue = [];
  final Set<String> _savedEventIds = {};
  final Map<String, int> _lastViewed = {};
  int _nextQueueId = 1;

  final StreamController<List<Follow>> _followsController =
      StreamController<List<Follow>>.broadcast();
  final StreamController<List<FollowRequest>> _inboundController =
      StreamController<List<FollowRequest>>.broadcast();
  final StreamController<List<FollowRequest>> _outboundController =
      StreamController<List<FollowRequest>>.broadcast();

  List<Follow> _snapshotFollows() =>
      _follows.values.where((f) => f.status == 'active').toList();
  List<FollowRequest> _snapshotInbound() =>
      _inboundRequests.where((r) => r.status == 'pending').toList();
  List<FollowRequest> _snapshotOutbound() => _outboundRequests.toList();

  void _emitFollows() => _followsController.add(_snapshotFollows());
  void _emitInbound() => _inboundController.add(_snapshotInbound());
  void _emitOutbound() => _outboundController.add(_snapshotOutbound());

  /// Releases broadcast controllers. Call from tearDown when the test
  /// instance is no longer needed.
  Future<void> dispose() async {
    await _followsController.close();
    await _inboundController.close();
    await _outboundController.close();
  }

  // --- Identity ---

  @override
  Future<Identity?> getIdentity() async => _identity;

  @override
  Future<void> saveIdentity(Identity identity) async {
    _identity = identity;
  }

  // --- Follows ---

  @override
  Future<List<Follow>> getFollows() async =>
      _follows.values.where((f) => f.status == 'active').toList();

  @override
  Stream<List<Follow>> watchFollows() async* {
    yield _snapshotFollows();
    yield* _followsController.stream;
  }

  @override
  Future<Follow?> getFollow(String pubkey) async => _follows[pubkey];

  @override
  Future<void> saveFollow(Follow follow) async {
    _follows[follow.pubkey] = follow;
    _emitFollows();
  }

  @override
  Future<void> removeFollow(String pubkey) async {
    _follows.remove(pubkey);
    _emitFollows();
  }

  @override
  Future<void> updateLastSynced(String pubkey, int timestamp) async {
    final follow = _follows[pubkey];
    if (follow != null) {
      _follows[pubkey] = Follow(
        pubkey: follow.pubkey,
        displayName: follow.displayName,
        avatarHash: follow.avatarHash,
        connectionCard: follow.connectionCard,
        feedKey: follow.feedKey,
        feedKeyEpoch: follow.feedKeyEpoch,
        lastSyncedAt: timestamp,
        status: follow.status,
      );
      _emitFollows();
    }
  }

  // --- Events ---

  @override
  Future<List<Event>> getEvents({
    String? pubkey,
    int? since,
    int? until,
    int? limit,
  }) async {
    var results = _events.values.toList();
    if (pubkey != null) {
      results = results.where((e) => e.pubkey == pubkey).toList();
    }
    if (since != null) {
      results = results.where((e) => e.createdAt >= since).toList();
    }
    if (until != null) {
      results = results.where((e) => e.createdAt <= until).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null) {
      results = results.take(limit).toList();
    }
    return results;
  }

  @override
  Future<Event?> getEvent(String id) async => _events[id];

  @override
  Future<void> saveEvent(Event event) async {
    _events[event.id] = event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    _events.remove(id);
  }

  @override
  Future<List<Event>> getFeedEvents({int? since, int? limit}) async {
    final followedPubkeys = _follows.values
        .where((f) => f.status == 'active')
        .map((f) => f.pubkey)
        .toSet();
    final ownPubkey = _identity?.pubkey;

    final tombstoned = _tombstonedIds();

    var results = _events.values.where((e) {
      final fromIncludedAuthor =
          e.pubkey == ownPubkey || followedPubkeys.contains(e.pubkey);
      return fromIncludedAuthor &&
          e.kind.value == 1 &&
          !tombstoned.contains(e.id);
    }).toList();

    if (since != null) {
      results = results.where((e) => e.createdAt >= since).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null) {
      results = results.take(limit).toList();
    }
    return results;
  }

  @override
  Future<List<Event>> getProfilePosts(String pubkey, {int? limit}) async {
    final tombstoned = _tombstonedIds(authorFilter: pubkey);
    var results = _events.values.where((e) {
      return e.pubkey == pubkey &&
          e.kind.value == 1 &&
          !tombstoned.contains(e.id);
    }).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null) {
      results = results.take(limit).toList();
    }
    return results;
  }

  @override
  Future<bool> isEventSaved(String id) async => _savedEventIds.contains(id);

  @override
  Future<void> setEventSaved(String id, bool saved) async {
    if (saved) {
      _savedEventIds.add(id);
    } else {
      _savedEventIds.remove(id);
    }
  }

  @override
  Future<void> setEventLastViewed(String id, int timestamp) async {
    _lastViewed[id] = timestamp;
  }

  /// Returns the set of event ids that have a kind=6 tombstone from the
  /// same author. If [authorFilter] is set, restricts the lookup.
  Set<String> _tombstonedIds({String? authorFilter}) {
    final byAuthor = <String, Set<String>>{};
    for (final e in _events.values) {
      if (e.kind.value != 6) continue;
      if (e.ref == null) continue;
      if (authorFilter != null && e.pubkey != authorFilter) continue;
      byAuthor.putIfAbsent(e.pubkey, () => <String>{}).add(e.ref!);
    }
    final out = <String>{};
    for (final e in _events.values) {
      if (byAuthor[e.pubkey]?.contains(e.id) ?? false) {
        out.add(e.id);
      }
    }
    return out;
  }

  // --- Media cache ---

  @override
  Future<CachedMedia?> getMedia(String hash) async => _mediaCache[hash];

  @override
  Future<void> saveMedia(CachedMedia media) async {
    _mediaCache[media.hash] = media;
  }

  @override
  Future<void> deleteMedia(String hash) async {
    _mediaCache.remove(hash);
  }

  @override
  Future<int> getMediaCacheSize() async {
    var total = 0;
    for (final m in _mediaCache.values) {
      total += m.size;
    }
    return total;
  }

  @override
  Future<void> evictMedia(int targetSize) async {
    final sorted = _mediaCache.values.toList()
      ..sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
    var totalSize = await getMediaCacheSize();
    for (final media in sorted) {
      if (totalSize <= targetSize) break;
      _mediaCache.remove(media.hash);
      totalSize -= media.size;
    }
  }

  // --- Follow requests ---

  @override
  Future<List<FollowRequest>> getInboundRequests() async =>
      _inboundRequests.where((r) => r.status == 'pending').toList();

  @override
  Stream<List<FollowRequest>> watchInboundRequests() async* {
    yield _snapshotInbound();
    yield* _inboundController.stream;
  }

  @override
  Future<List<FollowRequest>> getInboundRequestsByStatus(String status) async =>
      _inboundRequests.where((r) => r.status == status).toList();

  @override
  Future<FollowRequest?> getInboundRequest(String pubkey) async {
    for (final r in _inboundRequests) {
      if (r.pubkey == pubkey) return r;
    }
    return null;
  }

  @override
  Future<void> saveInboundRequest(FollowRequest request) async {
    final index = _inboundRequests.indexWhere((r) => r.pubkey == request.pubkey);
    if (index >= 0) {
      _inboundRequests[index] = request;
    } else {
      _inboundRequests.add(request);
    }
    _emitInbound();
  }

  @override
  Future<void> updateInboundRequestStatus(
    String pubkey,
    String status,
  ) async {
    final index = _inboundRequests.indexWhere((r) => r.pubkey == pubkey);
    if (index >= 0) {
      final old = _inboundRequests[index];
      _inboundRequests[index] = FollowRequest(
        pubkey: old.pubkey,
        payload: old.payload,
        createdAt: old.createdAt,
        requestTimestamp: old.requestTimestamp,
        status: status,
      );
      _emitInbound();
    }
  }

  @override
  Future<void> deleteInboundRequest(String pubkey) async {
    _inboundRequests.removeWhere((r) => r.pubkey == pubkey);
    _emitInbound();
  }

  @override
  Future<List<FollowRequest>> getOutboundRequests() async =>
      _outboundRequests.toList();

  @override
  Stream<List<FollowRequest>> watchOutboundRequests() async* {
    yield _snapshotOutbound();
    yield* _outboundController.stream;
  }

  @override
  Future<FollowRequest?> getOutboundRequest(String pubkey) async {
    for (final r in _outboundRequests) {
      if (r.pubkey == pubkey) return r;
    }
    return null;
  }

  @override
  Future<void> saveOutboundRequest(FollowRequest request) async {
    final index = _outboundRequests.indexWhere((r) => r.pubkey == request.pubkey);
    if (index >= 0) {
      _outboundRequests[index] = request;
    } else {
      _outboundRequests.add(request);
    }
    _emitOutbound();
  }

  @override
  Future<void> updateOutboundRequestStatus(
    String pubkey,
    String status,
  ) async {
    final index = _outboundRequests.indexWhere((r) => r.pubkey == pubkey);
    if (index >= 0) {
      final old = _outboundRequests[index];
      _outboundRequests[index] = FollowRequest(
        pubkey: old.pubkey,
        payload: old.payload,
        createdAt: old.createdAt,
        requestTimestamp: old.requestTimestamp,
        status: status,
      );
      _emitOutbound();
    }
  }

  @override
  Future<void> deleteOutboundRequest(String pubkey) async {
    _outboundRequests.removeWhere((r) => r.pubkey == pubkey);
    _emitOutbound();
  }

  // --- Unknown envelope items ---

  final List<UnknownEnvelopeItem> _unknownItems = [];

  @override
  Future<void> saveUnknownEnvelopeItem(UnknownEnvelopeItem item) async {
    _unknownItems.add(item);
  }

  @override
  Future<List<UnknownEnvelopeItem>> getUnknownEnvelopeItemsByType(
    String type,
  ) async =>
      _unknownItems.where((i) => i.type == type).toList();

  // --- Outbound queue ---

  @override
  Future<void> enqueue(String targetPubkey, Uint8List eventBlob) async {
    _queue.add(QueuedEvent(
      id: _nextQueueId++,
      targetPubkey: targetPubkey,
      eventBlob: eventBlob,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
  }

  @override
  Future<List<QueuedEvent>> dequeue(String targetPubkey) async =>
      _queue.where((q) => q.targetPubkey == targetPubkey).toList();

  @override
  Future<void> incrementRetry(int id) async {
    final index = _queue.indexWhere((q) => q.id == id);
    if (index >= 0) {
      final old = _queue[index];
      _queue[index] = QueuedEvent(
        id: old.id,
        targetPubkey: old.targetPubkey,
        eventBlob: old.eventBlob,
        createdAt: old.createdAt,
        retryCount: old.retryCount + 1,
      );
    }
  }

  @override
  Future<void> removeFromQueue(int id) async {
    _queue.removeWhere((q) => q.id == id);
  }

  // --- Retention ---

  @override
  Future<int> evictOldEvents(
    int maxAgeSeconds,
    int graceLastViewedSeconds,
  ) async {
    // No-op for mock — retention logic tested in Plan 02/12.
    return 0;
  }

  @override
  Future<int> evictMediaOverLimit(int maxBytes) async {
    return 0;
  }
}
