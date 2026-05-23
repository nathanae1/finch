import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/relay_paired_owner_table.dart';
import '../tables/relay_pairing_table.dart';
import '../tables/served_events_table.dart';
import '../tables/served_follow_requests_table.dart';
import '../tables/served_media_table.dart';

part 'relay_dao.g.dart';

/// Storage operations for Relay mode (Plan 15).
///
/// Aggregates accessors for the five tables that exist only when a
/// Starling install is acting as a Relay:
///
/// - `relay_paired_owner_entries`: singleton owner pubkey
/// - `relay_pairing_entries`: one-shot pairing tokens
/// - `served_event_entries`: raw EncryptedEvent blobs
/// - `served_media_entries`: encrypted media on disk
/// - `served_follow_request_entries`: queued follow requests for the Owner
@DriftAccessor(
  tables: [
    RelayPairedOwnerEntries,
    RelayPairingEntries,
    ServedEventEntries,
    ServedMediaEntries,
    ServedFollowRequestEntries,
  ],
)
class RelayDao extends DatabaseAccessor<AppDatabase>
    with _$RelayDaoMixin {
  RelayDao(super.db);

  // --- relay_paired_owner ---

  Future<RelayPairedOwnerEntry?> getPairedOwner() =>
      (select(relayPairedOwnerEntries)..limit(1)).getSingleOrNull();

  Future<void> setPairedOwner(String pubkey, int boundAt) async {
    await delete(relayPairedOwnerEntries).go();
    await into(relayPairedOwnerEntries).insert(
      RelayPairedOwnerEntriesCompanion.insert(
        pubkey: pubkey,
        boundAt: boundAt,
      ),
    );
  }

  Future<void> clearPairedOwner() =>
      delete(relayPairedOwnerEntries).go();

  // --- relay_pairing ---

  /// Replaces any prior token row with a fresh one. The Relay only ever
  /// has one active pairing token at a time.
  Future<void> writePairingToken({
    required Uint8List token,
    required int createdAt,
    required int expiresAt,
  }) async {
    await delete(relayPairingEntries).go();
    await into(relayPairingEntries).insert(
      RelayPairingEntriesCompanion.insert(
        token: token,
        createdAt: createdAt,
        expiresAt: expiresAt,
      ),
    );
  }

  Future<RelayPairingEntry?> getActivePairingToken() =>
      (select(relayPairingEntries)..limit(1)).getSingleOrNull();

  Future<void> markTokenConsumed(Uint8List token, int consumedAt) =>
      (update(relayPairingEntries)
            ..where((t) => t.token.equals(token)))
          .write(RelayPairingEntriesCompanion(
        consumedAt: Value(consumedAt),
      ));

  Future<void> clearPairingToken() =>
      delete(relayPairingEntries).go();

  // --- served_events ---

  Future<void> writeServedEvent(
    ServedEventEntriesCompanion entry,
  ) =>
      into(servedEventEntries).insert(
        entry,
        mode: InsertMode.insertOrReplace,
      );

  Future<int> servedEventCount() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM served_event_entries',
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<ServedEventEntry>> servedEventsSince(int since) =>
      (select(servedEventEntries)
            ..where((e) => e.createdAt.isBiggerThanValue(since))
            ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
          .get();

  /// Lightweight `(id, created_at)` rows for `GET /manifest`. Optional
  /// `since` / `until` window; results are newest-first (matching the
  /// social-mode manifest's `has_older` paging contract — clients page
  /// older by setting `until = oldestReturned.createdAt - 1`).
  Future<List<({String id, int createdAt})>> manifestRows({
    int? since,
    int? until,
    required int limit,
  }) async {
    final query = select(servedEventEntries);
    if (since != null) {
      query.where((e) => e.createdAt.isBiggerThanValue(since));
    }
    if (until != null) {
      query.where((e) => e.createdAt.isSmallerOrEqualValue(until));
    }
    query
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
      ..limit(limit);
    final rows = await query.get();
    return [
      for (final r in rows) (id: r.id, createdAt: r.createdAt),
    ];
  }

  Future<List<ServedEventEntry>> servedEventsInWindow(
    int since,
    int until,
  ) =>
      (select(servedEventEntries)
            ..where((e) =>
                e.createdAt.isBiggerThanValue(since) &
                e.createdAt.isSmallerOrEqualValue(until))
            ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
          .get();

  Future<void> clearServedEvents() =>
      delete(servedEventEntries).go();

  // --- served_media ---

  Future<void> writeServedMedia(
    ServedMediaEntriesCompanion entry,
  ) =>
      into(servedMediaEntries).insert(
        entry,
        mode: InsertMode.insertOrReplace,
      );

  Future<ServedMediaEntry?> getServedMedia(String hash) =>
      (select(servedMediaEntries)..where((m) => m.hash.equals(hash)))
          .getSingleOrNull();

  Future<int> servedMediaBytesTotal() async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(size), 0) AS s FROM served_media_entries',
    ).getSingle();
    return row.read<int>('s');
  }

  Future<void> clearServedMedia() =>
      delete(servedMediaEntries).go();

  // --- served_follow_requests ---

  Future<void> queueServedFollowRequest(
    ServedFollowRequestEntriesCompanion entry,
  ) =>
      into(servedFollowRequestEntries).insert(
        entry,
        mode: InsertMode.insertOrReplace,
      );

  Future<List<ServedFollowRequestEntry>> pendingFollowRequests() =>
      (select(servedFollowRequestEntries)
            ..where((r) => r.status.equals('pending'))
            ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
          .get();

  Future<void> clearServedFollowRequests() =>
      delete(servedFollowRequestEntries).go();
}
