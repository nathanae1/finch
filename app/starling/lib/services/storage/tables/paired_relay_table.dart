import 'package:drift/drift.dart';

/// Phone-side singleton recording the Relay the Owner has paired with.
///
/// Written on successful `/pair` round-trip. `relayId` is the
/// Relay-returned stable identifier (`blake2b_256(owner_pubkey ||
/// relay_onion)`) — a re-pair against the same Relay re-uses the same
/// id; pairing a different Relay produces a new id. `relayOnion` is
/// what the phone dials for `POST /events` / `POST /media` and what it
/// inserts into its Connection card as an `Endpoint(type: 'relay')`.
///
/// `relayBackfillComplete` tracks whether the one-shot initial backfill
/// of own events + media to the Relay has finished. Set to 0 on pair,
/// flipped to 1 once the iterator drains.
class PairedRelayEntries extends Table {
  TextColumn get relayId => text()();
  TextColumn get relayOnion => text()();
  IntColumn get pairedAt => integer()();
  IntColumn get relayBackfillComplete =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {relayId};
}
