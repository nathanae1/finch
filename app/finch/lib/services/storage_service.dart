import 'dart:typed_data';

import '../models/models.dart';
import 'types.dart';

/// Abstract interface for all persistent storage operations.
///
/// Default implementation uses SQLCipher via Drift (Plan 02).
/// Mock implementation uses in-memory maps.
abstract class StorageService {
  // --- Identity ---

  Future<Identity?> getIdentity();

  Future<void> saveIdentity(Identity identity);

  // --- Follows ---

  Future<List<Follow>> getFollows();

  Future<Follow?> getFollow(String pubkey);

  Future<void> saveFollow(Follow follow);

  Future<void> removeFollow(String pubkey);

  Future<void> updateLastSynced(String pubkey, int timestamp);

  // --- Events ---

  Future<List<Event>> getEvents({
    String? pubkey,
    int? since,
    int? until,
    int? limit,
  });

  Future<Event?> getEvent(String id);

  Future<void> saveEvent(Event event);

  Future<void> deleteEvent(String id);

  /// Feed events (own + all followed), ordered by created_at DESC.
  Future<List<Event>> getFeedEvents({int? since, int? limit});

  // --- Media cache ---

  Future<CachedMedia?> getMedia(String hash);

  Future<void> saveMedia(CachedMedia media);

  Future<void> deleteMedia(String hash);

  Future<int> getMediaCacheSize();

  Future<void> evictMedia(int targetSize);

  // --- Follow requests ---

  Future<List<FollowRequest>> getInboundRequests();

  Future<void> saveInboundRequest(FollowRequest request);

  Future<void> updateInboundRequestStatus(String pubkey, String status);

  Future<List<FollowRequest>> getOutboundRequests();

  Future<void> saveOutboundRequest(FollowRequest request);

  Future<void> updateOutboundRequestStatus(String pubkey, String status);

  // --- Outbound queue ---

  Future<void> enqueue(String targetPubkey, Uint8List eventBlob);

  Future<List<QueuedEvent>> dequeue(String targetPubkey);

  Future<void> incrementRetry(int id);

  Future<void> removeFromQueue(int id);

  // --- Retention ---

  /// Returns number of events evicted.
  Future<int> evictOldEvents(int maxAgeSeconds, int graceLastViewedSeconds);

  /// Returns number of media entries evicted.
  Future<int> evictMediaOverLimit(int maxBytes);
}
