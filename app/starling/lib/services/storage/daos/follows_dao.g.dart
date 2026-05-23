// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follows_dao.dart';

// ignore_for_file: type=lint
mixin _$FollowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FollowEntriesTable get followEntries => attachedDatabase.followEntries;
  FollowsDaoManager get managers => FollowsDaoManager(this);
}

class FollowsDaoManager {
  final _$FollowsDaoMixin _db;
  FollowsDaoManager(this._db);
  $$FollowEntriesTableTableManager get followEntries =>
      $$FollowEntriesTableTableManager(_db.attachedDatabase, _db.followEntries);
}
