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
      Expression<bool> condition = e.pubkey.isIn(allPubkeys);
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

  Future<int> evictOldEvents(
    int maxAgeSeconds,
    int graceLastViewedSeconds,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cutoff = now - maxAgeSeconds;
    final graceCutoff = now - graceLastViewedSeconds;

    return (delete(eventEntries)
          ..where(
            (e) =>
                e.isOwn.equals(0) &
                e.createdAt.isSmallerThanValue(cutoff) &
                (e.lastViewed.isNull() |
                    e.lastViewed.isSmallerThanValue(graceCutoff)),
          ))
        .go();
  }
}
