import 'package:drift/drift.dart';

class MediaCacheEntries extends Table {
  TextColumn get hash => text()();
  TextColumn get path => text()();
  IntColumn get size => integer()();
  IntColumn get lastAccessed => integer()();

  @override
  Set<Column> get primaryKey => {hash};
}
