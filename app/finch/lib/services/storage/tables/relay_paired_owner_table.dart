import 'package:drift/drift.dart';

/// Singleton row recording which Owner Identity this Relay serves.
///
/// Written exactly once at first successful `/pair`. All subsequent
/// owner-only write endpoints (`POST /events`, `POST /media`) verify
/// `X-Finch-Pubkey` against this row via `OwnerSignatureMiddleware`.
///
/// "Unpair" deletes the row alongside `served_events`, `served_media`,
/// and `served_follow_requests`, returning the Relay to its pre-pair
/// state.
class RelayPairedOwnerEntries extends Table {
  TextColumn get pubkey => text()();
  IntColumn get boundAt => integer()();

  @override
  Set<Column> get primaryKey => {pubkey};
}
