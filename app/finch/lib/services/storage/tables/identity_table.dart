import 'package:drift/drift.dart';

class IdentityEntries extends Table {
  TextColumn get pubkey => text()();
  BlobColumn get feedKey => blob()();
  IntColumn get feedKeyEpoch =>
      integer().withDefault(const Constant(0))();
  TextColumn get recoveryPhrase => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {pubkey};
}
