import 'package:drift/drift.dart';

/// Opaque storage for `EnvelopeItem`s whose `type` we don't recognize. The
/// protocol spec requires clients to preserve and forward unknown items
/// during sync so a P2P network with no forced upgrades can carry data
/// added by newer clients without older clients silently dropping it.
///
/// v1 has only `type:"event"`, so this table is a forward-compat shell —
/// no consumer reads from it yet. Plan 11 (MLS) adds the second item type
/// and the path that surfaces these rows back over `/events`.
class UnknownEnvelopeItemEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The peer pubkey we received this item from. Lets us scope retention /
  /// purge by source if a peer turns hostile.
  TextColumn get sourcePubkey => text()();

  /// `Envelope.version` at receive time — useful when we eventually decide
  /// whether to forward the item back during sync.
  TextColumn get envelopeVersion => text()();

  /// The unknown `type` string, e.g. `"commit"` or `"receipt"`.
  TextColumn get type => text()();

  /// Raw payload bytes. We never decode these.
  BlobColumn get payload => blob()();

  /// Item-level extensions, raw CBOR (or null if absent).
  BlobColumn get extensions => blob().nullable()();

  IntColumn get receivedAt => integer()();
}
