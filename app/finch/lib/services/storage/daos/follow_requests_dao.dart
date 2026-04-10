import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/inbound_follow_requests_table.dart';
import '../tables/outbound_follow_requests_table.dart';

part 'follow_requests_dao.g.dart';

@DriftAccessor(
  tables: [InboundFollowRequestEntries, OutboundFollowRequestEntries],
)
class FollowRequestsDao extends DatabaseAccessor<AppDatabase>
    with _$FollowRequestsDaoMixin {
  FollowRequestsDao(super.db);

  // --- Inbound ---

  Future<List<InboundFollowRequestEntry>> getInboundPending() =>
      (select(inboundFollowRequestEntries)
            ..where((r) => r.status.equals('pending')))
          .get();

  Future<void> upsertInbound(
    InboundFollowRequestEntriesCompanion entry,
  ) =>
      into(inboundFollowRequestEntries).insertOnConflictUpdate(entry);

  Future<void> updateInboundStatus(String pubkey, String status) =>
      (update(inboundFollowRequestEntries)
            ..where((r) => r.pubkey.equals(pubkey)))
          .write(InboundFollowRequestEntriesCompanion(
        status: Value(status),
      ));

  // --- Outbound ---

  Future<List<OutboundFollowRequestEntry>> getOutbound() =>
      select(outboundFollowRequestEntries).get();

  Future<void> upsertOutbound(
    OutboundFollowRequestEntriesCompanion entry,
  ) =>
      into(outboundFollowRequestEntries).insertOnConflictUpdate(entry);

  Future<void> updateOutboundStatus(String pubkey, String status) =>
      (update(outboundFollowRequestEntries)
            ..where((r) => r.pubkey.equals(pubkey)))
          .write(OutboundFollowRequestEntriesCompanion(
        status: Value(status),
      ));
}
