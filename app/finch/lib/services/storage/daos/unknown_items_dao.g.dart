// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unknown_items_dao.dart';

// ignore_for_file: type=lint
mixin _$UnknownItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UnknownEnvelopeItemEntriesTable get unknownEnvelopeItemEntries =>
      attachedDatabase.unknownEnvelopeItemEntries;
  UnknownItemsDaoManager get managers => UnknownItemsDaoManager(this);
}

class UnknownItemsDaoManager {
  final _$UnknownItemsDaoMixin _db;
  UnknownItemsDaoManager(this._db);
  $$UnknownEnvelopeItemEntriesTableTableManager
  get unknownEnvelopeItemEntries =>
      $$UnknownEnvelopeItemEntriesTableTableManager(
        _db.attachedDatabase,
        _db.unknownEnvelopeItemEntries,
      );
}
