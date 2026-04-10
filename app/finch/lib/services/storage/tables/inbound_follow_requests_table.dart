import 'package:drift/drift.dart';

class InboundFollowRequestEntries extends Table {
  TextColumn get pubkey => text()();
  BlobColumn get encryptedEndpoints => blob()();
  IntColumn get createdAt => integer()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {pubkey};
}
