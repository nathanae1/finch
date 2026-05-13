// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_dao.dart';

// ignore_for_file: type=lint
mixin _$RelayDaoMixin on DatabaseAccessor<AppDatabase> {
  $RelayPairedOwnerEntriesTable get relayPairedOwnerEntries =>
      attachedDatabase.relayPairedOwnerEntries;
  $RelayPairingEntriesTable get relayPairingEntries =>
      attachedDatabase.relayPairingEntries;
  $ServedEventEntriesTable get servedEventEntries =>
      attachedDatabase.servedEventEntries;
  $ServedMediaEntriesTable get servedMediaEntries =>
      attachedDatabase.servedMediaEntries;
  $ServedFollowRequestEntriesTable get servedFollowRequestEntries =>
      attachedDatabase.servedFollowRequestEntries;
  RelayDaoManager get managers => RelayDaoManager(this);
}

class RelayDaoManager {
  final _$RelayDaoMixin _db;
  RelayDaoManager(this._db);
  $$RelayPairedOwnerEntriesTableTableManager get relayPairedOwnerEntries =>
      $$RelayPairedOwnerEntriesTableTableManager(
        _db.attachedDatabase,
        _db.relayPairedOwnerEntries,
      );
  $$RelayPairingEntriesTableTableManager get relayPairingEntries =>
      $$RelayPairingEntriesTableTableManager(
        _db.attachedDatabase,
        _db.relayPairingEntries,
      );
  $$ServedEventEntriesTableTableManager get servedEventEntries =>
      $$ServedEventEntriesTableTableManager(
        _db.attachedDatabase,
        _db.servedEventEntries,
      );
  $$ServedMediaEntriesTableTableManager get servedMediaEntries =>
      $$ServedMediaEntriesTableTableManager(
        _db.attachedDatabase,
        _db.servedMediaEntries,
      );
  $$ServedFollowRequestEntriesTableTableManager
  get servedFollowRequestEntries =>
      $$ServedFollowRequestEntriesTableTableManager(
        _db.attachedDatabase,
        _db.servedFollowRequestEntries,
      );
}
