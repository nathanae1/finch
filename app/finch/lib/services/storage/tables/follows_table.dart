import 'package:drift/drift.dart';

class FollowEntries extends Table {
  TextColumn get pubkey => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarHash => text().nullable()();
  TextColumn get connectionCard => text()();
  BlobColumn get feedKey => blob()();
  IntColumn get lastSyncedAt =>
      integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {pubkey};
}
