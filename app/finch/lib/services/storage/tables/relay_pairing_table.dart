import 'package:drift/drift.dart';

/// One-shot pairing token displayed in the Relay's first-run QR.
///
/// Single-use, 10-minute TTL. The token is bound into the signed claim
/// `blake2b_256("finch-relay-pair-v1" || owner_pubkey || relay_onion ||
/// pairing_token)` so a captured token can't redirect the pairing to a
/// different Relay.
///
/// On successful `/pair` the row's `consumedAt` is set; subsequent
/// `/pair` calls return 409. On expiry the dashboard regenerates a
/// fresh row (and a fresh QR).
class RelayPairingEntries extends Table {
  BlobColumn get token => blob()();
  IntColumn get createdAt => integer()();
  IntColumn get expiresAt => integer()();
  IntColumn get consumedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {token};
}
