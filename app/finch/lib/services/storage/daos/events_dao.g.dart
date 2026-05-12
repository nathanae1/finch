// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_dao.dart';

// ignore_for_file: type=lint
mixin _$EventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventEntriesTable get eventEntries => attachedDatabase.eventEntries;
  $FollowEntriesTable get followEntries => attachedDatabase.followEntries;
  $IdentityEntriesTable get identityEntries => attachedDatabase.identityEntries;
  EventsDaoManager get managers => EventsDaoManager(this);
}

class EventsDaoManager {
  final _$EventsDaoMixin _db;
  EventsDaoManager(this._db);
  $$EventEntriesTableTableManager get eventEntries =>
      $$EventEntriesTableTableManager(_db.attachedDatabase, _db.eventEntries);
  $$FollowEntriesTableTableManager get followEntries =>
      $$FollowEntriesTableTableManager(_db.attachedDatabase, _db.followEntries);
  $$IdentityEntriesTableTableManager get identityEntries =>
      $$IdentityEntriesTableTableManager(
        _db.attachedDatabase,
        _db.identityEntries,
      );
}
