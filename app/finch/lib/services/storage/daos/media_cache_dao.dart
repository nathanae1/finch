import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/media_cache_table.dart';

part 'media_cache_dao.g.dart';

@DriftAccessor(tables: [MediaCacheEntries])
class MediaCacheDao extends DatabaseAccessor<AppDatabase>
    with _$MediaCacheDaoMixin {
  MediaCacheDao(super.db);

  Future<MediaCacheEntry?> getMedia(String hash) =>
      (select(mediaCacheEntries)..where((m) => m.hash.equals(hash)))
          .getSingleOrNull();

  Future<void> upsertMedia(MediaCacheEntriesCompanion entry) =>
      into(mediaCacheEntries).insertOnConflictUpdate(entry);

  Future<void> deleteMedia(String hash) =>
      (delete(mediaCacheEntries)..where((m) => m.hash.equals(hash))).go();

  Future<int> getTotalSize() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(size), 0) AS total FROM media_cache_entries',
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<void> evictToSize(int targetSize) async {
    var totalSize = await getTotalSize();
    if (totalSize <= targetSize) return;

    final oldest = await (select(mediaCacheEntries)
          ..orderBy([(m) => OrderingTerm.asc(m.lastAccessed)]))
        .get();

    for (final entry in oldest) {
      if (totalSize <= targetSize) break;
      await (delete(mediaCacheEntries)
            ..where((m) => m.hash.equals(entry.hash)))
          .go();
      totalSize -= entry.size;
    }
  }

  Future<int> evictOverLimit(int maxBytes) async {
    var totalSize = await getTotalSize();
    if (totalSize <= maxBytes) return 0;

    final oldest = await (select(mediaCacheEntries)
          ..orderBy([(m) => OrderingTerm.asc(m.lastAccessed)]))
        .get();

    var evicted = 0;
    for (final entry in oldest) {
      if (totalSize <= maxBytes) break;
      await (delete(mediaCacheEntries)
            ..where((m) => m.hash.equals(entry.hash)))
          .go();
      totalSize -= entry.size;
      evicted++;
    }
    return evicted;
  }
}
