// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$MediaCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaCacheEntriesTable get mediaCacheEntries =>
      attachedDatabase.mediaCacheEntries;
  MediaCacheDaoManager get managers => MediaCacheDaoManager(this);
}

class MediaCacheDaoManager {
  final _$MediaCacheDaoMixin _db;
  MediaCacheDaoManager(this._db);
  $$MediaCacheEntriesTableTableManager get mediaCacheEntries =>
      $$MediaCacheEntriesTableTableManager(
        _db.attachedDatabase,
        _db.mediaCacheEntries,
      );
}
