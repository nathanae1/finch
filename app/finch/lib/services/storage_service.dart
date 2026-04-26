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

  Stream<List<Follow>> watchFollows();

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
  /// Filters to kind=1 posts and excludes posts with a kind=6 tombstone
  /// from the same author.
  Future<List<Event>> getFeedEvents({int? since, int? limit});

  /// Posts (kind=1) authored by [pubkey] for profile-grid rendering.
  /// Excludes tombstoned (kind=6 ref'd) posts. Ordered DESC.
  Future<List<Event>> getProfilePosts(String pubkey, {int? limit});

  /// Events whose `ref` points to [refId]. Used to load comments (kind=4),
  /// likes (kind=5), and tombstones (kind=6) for a single post. Ordered
  /// ASC by `created_at`. If [kind] is provided, filters to that kind.
  Future<List<Event>> getEventsByRef(String refId, {EventKind? kind});

  /// Events the local server should hand out to peers asking for the
  /// owner's content: own-authored events plus events from others whose
  /// `ref` points to an own event (received comments/likes/deletes that
  /// the owner re-distributes to other followers). Ordered DESC by
  /// `created_at`. Used by `GET /events`.
  Future<List<Event>> getOwnAndIncomingRefs(
    String ownerPubkey, {
    int? since,
    int? limit,
  });

  /// Local-only flag: has the viewer bookmarked/saved this post?
  Future<bool> isEventSaved(String id);

  /// Local-only flag toggle. Never produces a synced event.
  Future<void> setEventSaved(String id, bool saved);

  /// Updates the local `last_viewed` column used by retention's grace period.
  Future<void> setEventLastViewed(String id, int timestamp);

  // --- Media cache ---

  Future<CachedMedia?> getMedia(String hash);

  Future<void> saveMedia(CachedMedia media);

  Future<void> deleteMedia(String hash);

  Future<int> getMediaCacheSize();

  Future<void> evictMedia(int targetSize);

  // --- Follow requests ---

  Future<List<FollowRequest>> getInboundRequests();

  Stream<List<FollowRequest>> watchInboundRequests();

  Future<List<FollowRequest>> getInboundRequestsByStatus(String status);

  Future<FollowRequest?> getInboundRequest(String pubkey);

  Future<void> saveInboundRequest(FollowRequest request);

  Future<void> updateInboundRequestStatus(String pubkey, String status);

  Future<void> deleteInboundRequest(String pubkey);

  Future<List<FollowRequest>> getOutboundRequests();

  Stream<List<FollowRequest>> watchOutboundRequests();

  Future<FollowRequest?> getOutboundRequest(String pubkey);

  Future<void> saveOutboundRequest(FollowRequest request);

  Future<void> updateOutboundRequestStatus(String pubkey, String status);

  Future<void> deleteOutboundRequest(String pubkey);

  // --- Unknown envelope items (forward compat) ---

  /// Persist an EnvelopeItem with an unrecognized `type` so it can be
  /// preserved (and, in a later plan, forwarded). v1 has no read-side
  /// consumer; this is purely receive-and-store.
  Future<void> saveUnknownEnvelopeItem(UnknownEnvelopeItem item);

  Future<List<UnknownEnvelopeItem>> getUnknownEnvelopeItemsByType(
    String type,
  );

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
