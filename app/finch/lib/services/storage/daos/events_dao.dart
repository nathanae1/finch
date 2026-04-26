import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/events_table.dart';
import '../tables/follows_table.dart';
import '../tables/identity_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [EventEntries, FollowEntries, IdentityEntries])
class EventsDao extends DatabaseAccessor<AppDatabase>
    with _$EventsDaoMixin {
  EventsDao(super.db);

  Future<List<EventEntry>> getEvents({
    String? pubkey,
    int? since,
    int? until,
    int? limit,
  }) {
    final q = select(eventEntries);
    if (pubkey != null || since != null || until != null) {
      q.where((e) {
        Expression<bool> condition = const Constant(true);
        if (pubkey != null) {
          condition = condition & e.pubkey.equals(pubkey);
        }
        if (since != null) {
          condition = condition & e.createdAt.isBiggerOrEqualValue(since);
        }
        if (until != null) {
          condition = condition & e.createdAt.isSmallerOrEqualValue(until);
        }
        return condition;
      });
    }
    q.orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    if (limit != null) {
      q.limit(limit);
    }
    return q.get();
  }

  Future<EventEntry?> getEvent(String id) =>
      (select(eventEntries)..where((e) => e.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertEvent(EventEntriesCompanion entry) =>
      into(eventEntries).insertOnConflictUpdate(entry);

  Future<void> deleteEvent(String id) =>
      (delete(eventEntries)..where((e) => e.id.equals(id))).go();

  /// Feed events: kind=1 posts from own identity + active follows, with
  /// per-author kind=6 tombstones excluded. Newest first.
  Future<List<EventEntry>> getFeedEvents({int? since, int? limit}) async {
    final identity =
        await (select(identityEntries)..limit(1)).getSingleOrNull();
    final follows = await (select(followEntries)
          ..where((f) => f.status.equals('active')))
        .get();

    final allPubkeys = <String>{
      if (identity != null) identity.pubkey,
      ...follows.map((f) => f.pubkey),
    };

    if (allPubkeys.isEmpty) return [];

    final q = select(eventEntries);
    q.where((e) {
      Expression<bool> condition =
          e.pubkey.isIn(allPubkeys) & e.kind.equals(1) & _notTombstoned(e);
      if (since != null) {
        condition = condition & e.createdAt.isBiggerOrEqualValue(since);
      }
      return condition;
    });
    q.orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    if (limit != null) {
      q.limit(limit);
    }
    return q.get();
  }

  /// Posts authored by [pubkey] for grid display: kind=1 only, deletes
  /// (kind=6 with matching ref_id) excluded. Newest first.
  Future<List<EventEntry>> getProfilePosts(
    String pubkey, {
    int? limit,
  }) {
    final q = select(eventEntries);
    q.where((e) =>
        e.pubkey.equals(pubkey) & e.kind.equals(1) & _notTombstoned(e));
    q.orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    if (limit != null) {
      q.limit(limit);
    }
    return q.get();
  }

  Future<bool> isEventSaved(String id) async {
    final row = await (select(eventEntries)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    return row != null && row.isSaved == 1;
  }

  Future<void> setEventSaved(String id, bool saved) =>
      (update(eventEntries)..where((e) => e.id.equals(id))).write(
        EventEntriesCompanion(isSaved: Value(saved ? 1 : 0)),
      );

  Future<void> setLastViewed(String id, int timestamp) =>
      (update(eventEntries)..where((e) => e.id.equals(id))).write(
        EventEntriesCompanion(lastViewed: Value(timestamp)),
      );

  Future<int> evictOldEvents(
    int maxAgeSeconds,
    int graceLastViewedSeconds, {
    required int now,
  }) {
    final cutoff = now - maxAgeSeconds;
    final graceCutoff = now - graceLastViewedSeconds;

    return (delete(eventEntries)
          ..where(
            (e) =>
                e.isOwn.equals(0) &
                e.isSaved.equals(0) &
                e.createdAt.isSmallerThanValue(cutoff) &
                (e.lastViewed.isNull() |
                    e.lastViewed.isSmallerThanValue(graceCutoff)),
          ))
        .go();
  }

  /// `id NOT IN (SELECT ref_id FROM event_entries WHERE kind=6 AND
  /// pubkey=outer.pubkey AND ref_id IS NOT NULL)` — covered by `idx_events_ref`.
  Expression<bool> _notTombstoned($EventEntriesTable e) {
    final inner = alias(eventEntries, 'tomb');
    final tombstones = selectOnly(inner)
      ..addColumns([inner.refId])
      ..where(
        inner.kind.equals(6) &
            inner.pubkey.equalsExp(e.pubkey) &
            inner.refId.isNotNull(),
      );
    return e.id.isNotInQuery(tombstones);
  }
}
