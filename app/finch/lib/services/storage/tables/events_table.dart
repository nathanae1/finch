import 'package:drift/drift.dart';

class EventEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pubkey => text()();
  IntColumn get createdAt => integer()();
  IntColumn get kind => integer()();
  TextColumn get refId => text().nullable()();
  BlobColumn get content => blob()();
  TextColumn get mediaRefs => text().nullable()();
  BlobColumn get sig => blob()();
  IntColumn get isOwn =>
      integer().withDefault(const Constant(0))();
  IntColumn get fetchedAt => integer()();
  IntColumn get lastViewed => integer().nullable()();
  TextColumn get version =>
      text().withDefault(const Constant('2026-03-24'))();

  @override
  Set<Column> get primaryKey => {id};
}
