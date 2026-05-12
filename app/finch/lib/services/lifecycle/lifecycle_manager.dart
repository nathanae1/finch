import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/discovery_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/sync_provider.dart';
import '../../sync/peer_reachability_provider.dart';
import '../background/foreground_service_controller.dart';
import '../background/ios_background_handler.dart';
import '../background/workmanager_dispatcher.dart';
import '../follow_retry_pump.dart';
import '../sync_pump.dart';

/// Foreground lifecycle orchestration. Owns the long-lived pumps, the
/// memoized Tor init future, and the onion-publish state that used to live
/// inline on `_FinchAppState` in `main.dart`.
///
/// Three entry points map to the Flutter app lifecycle:
/// - [start] — once, from `initState`. Eager-reads HTTP server + mDNS
///   providers, kicks off Tor init, starts the pumps.
/// - [onResume]/[onPause] — from `WidgetsBindingObserver`. Restart or stop
///   the same services on foreground/background.
/// - [stop] — once, from `dispose`. Stops pumps and tears down subscriptions.
///
/// Background sync (WorkManager, BGTaskScheduler) does NOT use this class —
/// it has no Riverpod scope. See `runBackgroundSync` for that entry point.
class LifecycleManager {
  LifecycleManager({required this.ref});

  final WidgetRef ref;


  FollowRetryPump? _retryPump;
  SyncPump? _syncPump;
  ProviderSubscription<AsyncValue<int?>>? _torPortSub;

  /// Memoized Tor init future. Any caller — initState, lifecycle resume,
  /// the port listener — gets back the same in-flight Future, so concurrent
  /// triggers (e.g. resume right after launch) don't double-init Arti.
  Future<void>? _torInitFuture;

  /// Most-recent published onion address. Used to skip a redundant
  /// `createOnionService` when the HTTP port hasn't changed.
  String? _onionAddress;

  /// Call from `initState`. Wires the pumps and the port-change listener that
  /// publishes a Tor onion service whenever the HTTP server binds.
  void start() {
    // Eagerly start the embedded HTTP server. The provider waits for
    // identity to be loaded before it actually binds a port.
    ref.read(httpServerControllerProvider);
    // Eagerly bring up mDNS discovery; the controller no-ops until both
    // identity and the server port are ready.
    ref.read(discoveryControllerProvider);
    // Bring up the peer reachability monitor (Plan 11c). Probes run in the
    // background; consumers ask `bestConnectionFor(pubkey)` for a
    // pre-validated transport instead of doing their own cascade.
    unawaited(ref.read(peerReachabilityMonitorProvider).start());

    _retryPump = FollowRetryPump(followService: ref.read(followServiceProvider))
      ..start();
    _syncPump = SyncPump(
      runSync: () =>
          ref.read(syncControllerProvider.notifier).syncNow().then((_) {}),
    )..start();
    ref.read(reconnectPusherProvider).start();

    // Plan 11a: bring up Tor in parallel with everything else. Bootstrap
    // can take 10–30s on cold start; LAN sync stays available throughout.
    unawaited(_ensureTorInit());

    // Plan 14 Phase B: register the Android WorkManager periodic sync.
    // No-op on iOS (BGTaskScheduler is registered natively in AppDelegate).
    // Idempotent — `ExistingWorkPolicy.keep` means re-registering on every
    // resume doesn't reset the schedule.
    unawaited(initializeBackgroundSync());

    // Plan 14 Phase C: prepare the foreground service (Android only). The
    // service isn't started here — the user enables it from the Network
    // settings screen. Init is idempotent and cheap.
    ForegroundServiceController.instance.init();

    // Plan 14 Phase D: register the iOS BGTask Dart-side method channel
    // so when AppDelegate fires `BGAppRefreshTask` / `BGProcessingTask`,
    // the Swift handler can invoke `runBackgroundSync`. No-op on Android.
    IosBackgroundHandler.instance.install();

    // Re-publish the onion service whenever the HTTP server's bound port
    // changes (initial start, post-restart rebind). Arti reuses the persisted
    // keypair so the .onion address is stable across rebinds.
    _torPortSub = ref.listenManual<AsyncValue<int?>>(
      httpServerControllerProvider,
      (_, next) {
        final port = next.value;
        if (port != null) {
          unawaited(_publishOnion(port));
        }
      },
      fireImmediately: true,
    );
  }

  /// Call from `dispose`.
  Future<void> stop() async {
    unawaited(_retryPump?.stop());
    unawaited(_syncPump?.stop());
    unawaited(ref.read(reconnectPusherProvider).stop());
    _torPortSub?.close();
    _torPortSub = null;
  }

  /// Handle a foreground transition. Restart the HTTP server, re-init Tor,
  /// and resume the pumps.
  Future<void> onResume() async {
    _log('lifecycle=resumed');
    final notifier = ref.read(httpServerControllerProvider.notifier);
    unawaited(notifier.restart());
    unawaited(_ensureTorInit());
    _syncPump?.start();
    ref.read(reconnectPusherProvider).start();
  }

  /// Handle paused / detached / hidden. Shuts down the HTTP server, Tor, and
  /// the pumps — unless the Android foreground service is running, in which
  /// case we leave everything up so the device stays reachable in
  /// background (Plan 14 Phase C).
  Future<void> onPause() async {
    if (await ForegroundServiceController.instance.isRunning()) {
      _log('lifecycle=paused (fgservice on — keeping services live)');
      return;
    }
    _log('lifecycle=paused');
    final notifier = ref.read(httpServerControllerProvider.notifier);
    final tor = ref.read(torServiceProvider);
    unawaited(notifier.stop());
    _onionAddress = null;
    ref.read(onionAddressProvider.notifier).set(null);
    _torInitFuture = null;
    unawaited(tor.shutdown());
    unawaited(_syncPump?.stop());
    unawaited(ref.read(reconnectPusherProvider).stop());
  }

  Future<void> _ensureTorInit() {
    return _torInitFuture ??= () async {
      try {
        _log('tor.init begin');
        final tor = ref.read(torServiceProvider);
        _log('tor.init service=${tor.runtimeType}');
        final dir = await torDataDirectory();
        _log('tor.init dataDir=${dir.path}');
        await tor.init(dir.path);
        _log('tor.init complete socksPort=${tor.socksPort}');
      } catch (e, st) {
        _log('tor.init failed: $e\n$st');
        // Drop the cached future on failure so a future port event can
        // retry from a clean slate.
        _torInitFuture = null;
        rethrow;
      }
    }();
  }

  Future<void> _publishOnion(int port) async {
    if (_onionAddress != null) {
      _log('publishOnion skipped (already have $_onionAddress)');
      return;
    }
    try {
      _log('publishOnion begin port=$port');
      await _ensureTorInit();
      final tor = ref.read(torServiceProvider);
      _log('publishOnion calling createOnionService isReady=${tor.isReady}');
      final addr = await tor.createOnionService(port);
      _onionAddress = addr;
      ref.read(onionAddressProvider.notifier).set(addr);
      _log('onion=$addr port=$port');
    } catch (e, st) {
      _log('createOnionService failed: $e\n$st');
    }
  }

  void _log(String msg) {
    developer.log(msg, name: 'finch.tor');
    // ignore: avoid_print
    print('[finch.tor] $msg');
  }
}

/// Resolves Arti's data directory. Always under
/// `getApplicationSupportDirectory()` so iOS doesn't purge it under storage
/// pressure (Plan 14 Phase D: keeps the on-disk consensus + guards intact
/// across suspensions so warm bootstrap stays fast).
Future<Directory> torDataDirectory() async {
  final supportDir = await getApplicationSupportDirectory();
  final torDir = Directory('${supportDir.path}/tor');
  await torDir.create(recursive: true);
  return torDir;
}
