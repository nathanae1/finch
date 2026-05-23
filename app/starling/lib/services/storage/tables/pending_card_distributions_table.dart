import 'package:drift/drift.dart';

/// Connection card updates waiting to be delivered to a Follower.
///
/// When the Owner adds (or rotates) a Relay endpoint the phone signs the
/// new card and writes one row per existing Follower. The row is
/// consumed lazily: the manifest handler attaches the latest undelivered
/// row to the Follower's next `/manifest` response, and the Follower's
/// follow-up `card_seen_at` query parameter on subsequent requests
/// flips `distributed=1`.
///
/// Mirrors [PendingKeyDistributionEntries] in shape — only the payload
/// differs. `(targetPubkey, createdAt)` is the primary key; lookup
/// picks the highest `createdAt` with `distributed=0`.
class PendingCardDistributionEntries extends Table {
  TextColumn get targetPubkey => text()();
  BlobColumn get cardCbor => blob()();
  BlobColumn get sig => blob()();
  IntColumn get createdAt => integer()();
  IntColumn get distributed =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {targetPubkey, createdAt};
}
