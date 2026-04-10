
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:finch/services/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  EventEntriesCompanion makeEvent(
    String id, {
    int createdAt = 1000,
    bool isOwn = false,
    int? lastViewed,
  }) =>
      EventEntriesCompanion.insert(
        id: id,
        pubkey: isOwn ? 'me' : 'other',
        createdAt: createdAt,
        kind: 1,
        content: Uint8List.fromList([1]),
        sig: Uint8List.fromList(List.filled(64, 0)),
        fetchedAt: createdAt,
        isOwn: Value(isOwn ? 1 : 0),
        lastViewed: Value(lastViewed),
      );

  group('evictOldEvents', () {
    test('evicts old non-own events', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final old = now - 60 * 60 * 24 * 60; // 60 days ago

      await db.eventsDao.upsertEvent(makeEvent('old-1', createdAt: old));
      await db.eventsDao.upsertEvent(makeEvent('recent', createdAt: now));

      // maxAge = 30 days, graceLastViewed = 7 days
      final evicted = await db.eventsDao.evictOldEvents(
        30 * 24 * 60 * 60,
        7 * 24 * 60 * 60,
      );

      expect(evicted, equals(1));
      expect(await db.eventsDao.getEvent('old-1'), isNull);
      expect(await db.eventsDao.getEvent('recent'), isNotNull);
    });

    test('never evicts own events regardless of age', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final old = now - 60 * 60 * 24 * 60; // 60 days ago

      await db.eventsDao.upsertEvent(
        makeEvent('own-old', createdAt: old, isOwn: true),
      );

      final evicted = await db.eventsDao.evictOldEvents(
        30 * 24 * 60 * 60,
        7 * 24 * 60 * 60,
      );

      expect(evicted, equals(0));
      expect(await db.eventsDao.getEvent('own-old'), isNotNull);
    });

    test('respects last_viewed grace period', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final old = now - 60 * 60 * 24 * 60; // 60 days ago
      final recentView = now - 60 * 60 * 24 * 2; // 2 days ago

      await db.eventsDao.upsertEvent(
        makeEvent('viewed-recently', createdAt: old, lastViewed: recentView),
      );
      await db.eventsDao.upsertEvent(
        makeEvent('not-viewed', createdAt: old),
      );

      final evicted = await db.eventsDao.evictOldEvents(
        30 * 24 * 60 * 60,
        7 * 24 * 60 * 60,
      );

      expect(evicted, equals(1));
      expect(await db.eventsDao.getEvent('viewed-recently'), isNotNull);
      expect(await db.eventsDao.getEvent('not-viewed'), isNull);
    });
  });

  group('evictMediaOverLimit', () {
    test('evicts oldest media when over limit', () async {
      await db.mediaCacheDao.upsertMedia(
        MediaCacheEntriesCompanion.insert(
          hash: 'oldest',
          path: '/oldest',
          size: 500,
          lastAccessed: 100,
        ),
      );
      await db.mediaCacheDao.upsertMedia(
        MediaCacheEntriesCompanion.insert(
          hash: 'newest',
          path: '/newest',
          size: 500,
          lastAccessed: 200,
        ),
      );

      final evicted = await db.mediaCacheDao.evictOverLimit(600);
      expect(evicted, equals(1));
      expect(await db.mediaCacheDao.getMedia('oldest'), isNull);
      expect(await db.mediaCacheDao.getMedia('newest'), isNotNull);
    });

    test('does nothing when under limit', () async {
      await db.mediaCacheDao.upsertMedia(
        MediaCacheEntriesCompanion.insert(
          hash: 'h1',
          path: '/h1',
          size: 100,
          lastAccessed: 100,
        ),
      );

      final evicted = await db.mediaCacheDao.evictOverLimit(1000);
      expect(evicted, equals(0));
    });
  });
}
