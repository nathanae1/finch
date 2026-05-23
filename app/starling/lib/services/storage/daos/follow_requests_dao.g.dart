// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_requests_dao.dart';

// ignore_for_file: type=lint
mixin _$FollowRequestsDaoMixin on DatabaseAccessor<AppDatabase> {
  $InboundFollowRequestEntriesTable get inboundFollowRequestEntries =>
      attachedDatabase.inboundFollowRequestEntries;
  $OutboundFollowRequestEntriesTable get outboundFollowRequestEntries =>
      attachedDatabase.outboundFollowRequestEntries;
  FollowRequestsDaoManager get managers => FollowRequestsDaoManager(this);
}

class FollowRequestsDaoManager {
  final _$FollowRequestsDaoMixin _db;
  FollowRequestsDaoManager(this._db);
  $$InboundFollowRequestEntriesTableTableManager
  get inboundFollowRequestEntries =>
      $$InboundFollowRequestEntriesTableTableManager(
        _db.attachedDatabase,
        _db.inboundFollowRequestEntries,
      );
  $$OutboundFollowRequestEntriesTableTableManager
  get outboundFollowRequestEntries =>
      $$OutboundFollowRequestEntriesTableTableManager(
        _db.attachedDatabase,
        _db.outboundFollowRequestEntries,
      );
}
