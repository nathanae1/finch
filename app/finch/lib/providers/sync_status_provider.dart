import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../widgets/sync_dot.dart';
import 'discovery_provider.dart';
import 'follows_provider.dart';
import 'sync_provider.dart';

part 'sync_status_provider.g.dart';

/// Sync status surfaced in `FeedSyncSearchBar`. Derived from the sync
/// controller's run phase + the live mDNS peer cache + the active
/// follows list.
class SyncStatus {
  const SyncStatus({
    required this.state,
    this.lastSyncedAtSeconds,
    this.reachableFriends = 0,
    this.waitingForName,
  });

  final SyncState state;

  /// Unix seconds. Null means "not yet synced this session".
  final int? lastSyncedAtSeconds;

  final int reachableFriends;

  /// Display name shown in `waiting` state ("Waiting for {name}'s device…").
  /// Null when not in `waiting`.
  final String? waitingForName;
}

@riverpod
SyncStatus syncStatus(Ref ref) {
  final engineState = ref.watch(syncControllerProvider);
  final peers = ref.watch(discoveryControllerProvider).value ?? const {};
  final follows = ref.watch(followsStreamProvider).value ?? const [];

  final reachable = follows.where((f) => peers.containsKey(f.pubkey)).length;

  if (engineState.phase == SyncRunPhase.syncing) {
    return SyncStatus(
      state: SyncState.syncing,
      lastSyncedAtSeconds: engineState.lastSyncAt,
      reachableFriends: reachable,
    );
  }
  if (follows.isEmpty) {
    return SyncStatus(
      state: SyncState.synced,
      lastSyncedAtSeconds: engineState.lastSyncAt,
      reachableFriends: 0,
    );
  }
  if (reachable == 0) {
    return SyncStatus(
      state: SyncState.offline,
      lastSyncedAtSeconds: engineState.lastSyncAt,
      reachableFriends: 0,
    );
  }
  return SyncStatus(
    state: SyncState.synced,
    lastSyncedAtSeconds: engineState.lastSyncAt,
    reachableFriends: reachable,
  );
}
