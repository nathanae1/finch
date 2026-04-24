import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/models.dart';
import '../clock.dart';
import '../storage_service.dart';
import '../types.dart';
import 'converters.dart';
import 'database.dart';

class DriftStorageService implements StorageService {
  DriftStorageService(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  // --- Identity ---

  @override
  Future<Identity?> getIdentity() async {
    final row = await _db.identityDao.getIdentity();
    return row == null ? null : identityFromRow(row);
  }

  @override
  Future<void> saveIdentity(Identity identity) =>
      _db.identityDao.upsertIdentity(identityToCompanion(identity));

  // --- Follows ---

  @override
  Future<List<Follow>> getFollows() async {
    final rows = await _db.followsDao.getActiveFollows();
    return rows.map(followFromRow).toList();
  }

  @override
  Future<Follow?> getFollow(String pubkey) async {
    final row = await _db.followsDao.getFollow(pubkey);
    return row == null ? null : followFromRow(row);
  }

  @override
  Future<void> saveFollow(Follow follow) =>
      _db.followsDao.upsertFollow(followToCompanion(follow));

  @override
  Future<void> removeFollow(String pubkey) =>
      _db.followsDao.removeFollow(pubkey);

  @override
  Future<void> updateLastSynced(String pubkey, int timestamp) =>
      _db.followsDao.updateLastSynced(pubkey, timestamp);

  // --- Events ---

  @override
  Future<List<Event>> getEvents({
    String? pubkey,
    int? since,
    int? until,
    int? limit,
  }) async {
    final rows = await _db.eventsDao.getEvents(
      pubkey: pubkey,
      since: since,
      until: until,
      limit: limit,
    );
    return rows.map(eventFromRow).toList();
  }

  @override
  Future<Event?> getEvent(String id) async {
    final row = await _db.eventsDao.getEvent(id);
    return row == null ? null : eventFromRow(row);
  }

  @override
  Future<void> saveEvent(Event event) async {
    final identity = await _db.identityDao.getIdentity();
    final isOwn = identity != null && identity.pubkey == event.pubkey;
    await _db.eventsDao.upsertEvent(
      eventToCompanion(event, isOwn: isOwn, fetchedAt: _clock.nowUnixSeconds()),
    );
  }

  @override
  Future<void> deleteEvent(String id) => _db.eventsDao.deleteEvent(id);

  @override
  Future<List<Event>> getFeedEvents({int? since, int? limit}) async {
    final rows =
        await _db.eventsDao.getFeedEvents(since: since, limit: limit);
    return rows.map(eventFromRow).toList();
  }

  // --- Media cache ---

  @override
  Future<CachedMedia?> getMedia(String hash) async {
    final row = await _db.mediaCacheDao.getMedia(hash);
    return row == null ? null : cachedMediaFromRow(row);
  }

  @override
  Future<void> saveMedia(CachedMedia media) =>
      _db.mediaCacheDao.upsertMedia(cachedMediaToCompanion(media));

  @override
  Future<void> deleteMedia(String hash) =>
      _db.mediaCacheDao.deleteMedia(hash);

  @override
  Future<int> getMediaCacheSize() => _db.mediaCacheDao.getTotalSize();

  @override
  Future<void> evictMedia(int targetSize) =>
      _db.mediaCacheDao.evictToSize(targetSize);

  // --- Follow requests ---

  @override
  Future<List<FollowRequest>> getInboundRequests() async {
    final rows = await _db.followRequestsDao.getInboundPending();
    return rows.map(inboundRequestFromRow).toList();
  }

  @override
  Future<void> saveInboundRequest(FollowRequest request) =>
      _db.followRequestsDao.upsertInbound(
        InboundFollowRequestEntriesCompanion.insert(
          pubkey: request.pubkey,
          encryptedEndpoints: request.payload,
          createdAt: request.createdAt,
          status: Value(request.status),
        ),
      );

  @override
  Future<void> updateInboundRequestStatus(String pubkey, String status) =>
      _db.followRequestsDao.updateInboundStatus(pubkey, status);

  @override
  Future<List<FollowRequest>> getOutboundRequests() async {
    final rows = await _db.followRequestsDao.getOutbound();
    return rows.map(outboundRequestFromRow).toList();
  }

  @override
  Future<void> saveOutboundRequest(FollowRequest request) =>
      _db.followRequestsDao.upsertOutbound(
        OutboundFollowRequestEntriesCompanion.insert(
          pubkey: request.pubkey,
          connectionCard: utf8.decode(request.payload),
          createdAt: request.createdAt,
          status: Value(request.status),
        ),
      );

  @override
  Future<void> updateOutboundRequestStatus(String pubkey, String status) =>
      _db.followRequestsDao.updateOutboundStatus(pubkey, status);

  // --- Outbound queue ---

  @override
  Future<void> enqueue(String targetPubkey, Uint8List eventBlob) =>
      _db.outboundQueueDao.enqueue(
        OutboundQueueEntriesCompanion.insert(
          targetPubkey: targetPubkey,
          eventBlob: eventBlob,
          createdAt: _clock.nowUnixSeconds(),
        ),
      );

  @override
  Future<List<QueuedEvent>> dequeue(String targetPubkey) async {
    final rows = await _db.outboundQueueDao.dequeue(targetPubkey);
    return rows.map(queuedEventFromRow).toList();
  }

  @override
  Future<void> incrementRetry(int id) =>
      _db.outboundQueueDao.incrementRetry(id);

  @override
  Future<void> removeFromQueue(int id) =>
      _db.outboundQueueDao.removeFromQueue(id);

  // --- Retention ---

  @override
  Future<int> evictOldEvents(
    int maxAgeSeconds,
    int graceLastViewedSeconds,
  ) =>
      _db.eventsDao.evictOldEvents(
        maxAgeSeconds,
        graceLastViewedSeconds,
        now: _clock.nowUnixSeconds(),
      );

  @override
  Future<int> evictMediaOverLimit(int maxBytes) =>
      _db.mediaCacheDao.evictOverLimit(maxBytes);
}
