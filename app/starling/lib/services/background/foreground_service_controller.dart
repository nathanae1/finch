import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Plan 14 Phase C — opt-in Android foreground service.
///
/// The Starling foreground service exists to keep the Android process alive in
/// the background. A foreground notification prevents Android from suspending
/// the process, which means the main UI isolate's HTTP server, Tor onion
/// service, and mDNS registration all keep serving content to peers while
/// the app is in the background. This turns any phone into a near-relay
/// (Plan 14 design intent → Plan 15 builds on this).
///
/// The [_NoopTaskHandler] does no work itself — the service notification
/// alone is what gates the OS lifecycle. The main isolate's
/// [LifecycleManager.onPause] checks [FlutterForegroundTask.isRunningService]
/// and short-circuits the teardown when the service is running.
///
/// iOS is a no-op for the whole feature: there is no equivalent persistent
/// foreground concept (Plan 14 Phase D explains the iOS warm-start path).
class ForegroundServiceController {
  ForegroundServiceController._();

  static final ForegroundServiceController instance =
      ForegroundServiceController._();

  /// Has [init] been called this process. Safe to call multiple times.
  bool _initialized = false;

  /// Idempotent. Caller can invoke at app startup; no service is started
  /// until [start] is called.
  void init() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'starling_foreground',
        channelName: 'Starling background mode',
        channelDescription:
            'Keeps Starling reachable to your friends while the app is in '
            'the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // No sound or vibration — this is a status notification, not an alert.
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Returns whether the FG service is currently running.
  Future<bool> isRunning() async {
    if (!Platform.isAndroid) return false;
    return FlutterForegroundTask.isRunningService;
  }

  /// Requests the runtime POST_NOTIFICATIONS permission needed on Android
  /// 13+. Returns true if the user grants it, false otherwise.
  Future<bool> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status == NotificationPermission.granted) return true;
    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  /// Start the FG service. Idempotent — returns true if a service is now
  /// running (whether or not we started it). Returns false on Android if
  /// permissions are denied or the service fails to start; always false
  /// on iOS.
  Future<bool> start() async {
    if (!Platform.isAndroid) return false;
    init();

    if (!await ensureNotificationPermission()) {
      developer.log(
        'foreground service: POST_NOTIFICATIONS denied — cannot start',
        name: 'starling.fgservice',
      );
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Starling is running',
      notificationText: 'Your phone is reachable to your friends in the '
          'background. Disable in Settings → Network.',
      callback: startForegroundCallback,
    );

    if (result is ServiceRequestSuccess) {
      developer.log('foreground service started', name: 'starling.fgservice');
      return true;
    }
    developer.log(
      'foreground service start failed: $result',
      name: 'starling.fgservice',
    );
    return false;
  }

  /// Stop the FG service. Idempotent.
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    final result = await FlutterForegroundTask.stopService();
    developer.log(
      'foreground service stop result=$result',
      name: 'starling.fgservice',
    );
  }
}

/// Top-level entry point for the foreground service isolate. Must stay
/// top-level and `@pragma('vm:entry-point')` so it survives AOT
/// tree-shaking. The handler does nothing — its sole purpose is to satisfy
/// the package's requirement that a service have a registered handler.
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_NoopTaskHandler());
}

class _NoopTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
