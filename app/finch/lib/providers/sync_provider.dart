import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/lan_network_service.dart';
import '../sync/peer_connection_factory.dart';
import '../sync/sync_engine.dart';
import 'service_providers.dart';

part 'sync_provider.g.dart';

/// Provides the singleton [PeerConnectionFactory] used by the sync engine
/// and `RemoteMediaFetcher`.
@riverpod
PeerConnectionFactory peerConnectionFactory(PeerConnectionFactoryRef ref) {
  return PeerConnectionFactory(mdns: ref.watch(mdnsServiceProvider));
}

/// LanNetworkService singleton. The default `networkServiceProvider` is
/// the abstract interface (mock by default); the concrete LAN client is
/// kept separate so the sync engine can call `fetchEnvelope`, which is a
/// LAN-specific method not yet on the cross-tier interface.
@riverpod
LanNetworkService lanNetworkService(LanNetworkServiceRef ref) {
  final mdns = ref.watch(mdnsServiceProvider);
  final svc = LanNetworkService(mdns: mdns);
  ref.onDispose(svc.close);
  return svc;
}

@riverpod
SyncEngine syncEngine(SyncEngineRef ref) {
  return SyncEngine(
    storage: ref.watch(storageServiceProvider),
    contentKey: ref.watch(contentKeyServiceProvider),
    transport: ref.watch(lanNetworkServiceProvider),
    peerFactory: ref.watch(peerConnectionFactoryProvider),
    clock: ref.watch(clockProvider),
  );
}

enum SyncRunPhase { idle, syncing }

class SyncEngineState {
  const SyncEngineState({
    required this.phase,
    this.lastReport,
    this.lastSyncAt,
    this.lastError,
  });
  final SyncRunPhase phase;
  final SyncReport? lastReport;
  final int? lastSyncAt;
  final String? lastError;

  SyncEngineState copyWith({
    SyncRunPhase? phase,
    SyncReport? lastReport,
    int? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) =>
      SyncEngineState(
        phase: phase ?? this.phase,
        lastReport: lastReport ?? this.lastReport,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  static const idle = SyncEngineState(phase: SyncRunPhase.idle);
}

/// Surfaces sync state to the UI and exposes [syncNow] for pull-to-refresh.
@riverpod
class SyncController extends _$SyncController {
  @override
  SyncEngineState build() => SyncEngineState.idle;

  Future<SyncReport> syncNow() async {
    if (state.phase == SyncRunPhase.syncing) {
      // Coalesce concurrent triggers — the in-flight sync's report is
      // what callers will see when it lands.
      return state.lastReport ?? const SyncReport(
        startedAt: 0,
        finishedAt: 0,
        peers: [],
      );
    }
    state = state.copyWith(phase: SyncRunPhase.syncing, clearError: true);
    final engine = ref.read(syncEngineProvider);
    try {
      final report = await engine.syncNow();
      state = SyncEngineState(
        phase: SyncRunPhase.idle,
        lastReport: report,
        lastSyncAt: report.finishedAt,
      );
      return report;
    } catch (e) {
      state = state.copyWith(
        phase: SyncRunPhase.idle,
        lastError: e.toString(),
      );
      rethrow;
    }
  }
}
