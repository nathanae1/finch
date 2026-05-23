// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_rotation_dao.dart';

// ignore_for_file: type=lint
mixin _$KeyRotationDaoMixin on DatabaseAccessor<AppDatabase> {
  $FeedKeyHistoryEntriesTable get feedKeyHistoryEntries =>
      attachedDatabase.feedKeyHistoryEntries;
  $FollowFeedKeyHistoryEntriesTable get followFeedKeyHistoryEntries =>
      attachedDatabase.followFeedKeyHistoryEntries;
  $PendingKeyDistributionEntriesTable get pendingKeyDistributionEntries =>
      attachedDatabase.pendingKeyDistributionEntries;
  KeyRotationDaoManager get managers => KeyRotationDaoManager(this);
}

class KeyRotationDaoManager {
  final _$KeyRotationDaoMixin _db;
  KeyRotationDaoManager(this._db);
  $$FeedKeyHistoryEntriesTableTableManager get feedKeyHistoryEntries =>
      $$FeedKeyHistoryEntriesTableTableManager(
        _db.attachedDatabase,
        _db.feedKeyHistoryEntries,
      );
  $$FollowFeedKeyHistoryEntriesTableTableManager
  get followFeedKeyHistoryEntries =>
      $$FollowFeedKeyHistoryEntriesTableTableManager(
        _db.attachedDatabase,
        _db.followFeedKeyHistoryEntries,
      );
  $$PendingKeyDistributionEntriesTableTableManager
  get pendingKeyDistributionEntries =>
      $$PendingKeyDistributionEntriesTableTableManager(
        _db.attachedDatabase,
        _db.pendingKeyDistributionEntries,
      );
}
