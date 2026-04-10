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
  int _nextQueueId = 1;

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
  Future<Follow?> getFollow(String pubkey) async => _follows[pubkey];

  @override
  Future<void> saveFollow(Follow follow) async {
    _follows[follow.pubkey] = follow;
  }

  @override
  Future<void> removeFollow(String pubkey) async {
    _follows.remove(pubkey);
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
        lastSyncedAt: timestamp,
        status: follow.status,
      );
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

    var results = _events.values.where((e) {
      return e.pubkey == ownPubkey || followedPubkeys.contains(e.pubkey);
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
  Future<void> saveInboundRequest(FollowRequest request) async {
    _inboundRequests.add(request);
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
        status: status,
      );
    }
  }

  @override
  Future<List<FollowRequest>> getOutboundRequests() async =>
      _outboundRequests.toList();

  @override
  Future<void> saveOutboundRequest(FollowRequest request) async {
    _outboundRequests.add(request);
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
        status: status,
      );
    }
  }

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
