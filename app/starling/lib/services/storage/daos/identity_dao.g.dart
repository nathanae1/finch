// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_dao.dart';

// ignore_for_file: type=lint
mixin _$IdentityDaoMixin on DatabaseAccessor<AppDatabase> {
  $IdentityEntriesTable get identityEntries => attachedDatabase.identityEntries;
  IdentityDaoManager get managers => IdentityDaoManager(this);
}

class IdentityDaoManager {
  final _$IdentityDaoMixin _db;
  IdentityDaoManager(this._db);
  $$IdentityEntriesTableTableManager get identityEntries =>
      $$IdentityEntriesTableTableManager(
        _db.attachedDatabase,
        _db.identityEntries,
      );
}
