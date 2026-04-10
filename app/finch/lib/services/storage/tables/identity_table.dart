import 'package:drift/drift.dart';

class IdentityEntries extends Table {
  TextColumn get pubkey => text()();
  BlobColumn get feedKey => blob()();
  TextColumn get recoveryPhrase => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {pubkey};
}
