import 'package:drift/drift.dart';

/// Inbound follow requests addressed to the Owner that the Relay queued
/// while the Owner was offline.
///
/// The Owner picks these up on their next sync — the Relay surfaces the
/// queue alongside the manifest response (mechanism: see relay-spec
/// `follow_requests` retrieval). Endpoints are stored encrypted; the
/// Relay can't decrypt them.
class ServedFollowRequestEntries extends Table {
  TextColumn get pubkey => text()();
  BlobColumn get encryptedEndpoints => blob()();
  IntColumn get createdAt => integer()();
  IntColumn get requestTimestamp =>
      integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {pubkey};
}
