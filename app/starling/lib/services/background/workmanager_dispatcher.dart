import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:workmanager/workmanager.dart';

import 'background_sync_runner.dart';

/// Plan 14 Phase B — Android background sync via WorkManager. iOS uses
/// BGTaskScheduler directly via native AppDelegate (Phase D), not this
/// dispatcher.
///
/// The unique task name used by `registerPeriodicTask` and `cancelByUniqueName`.
const String kBackgroundSyncTaskName = 'dev.starling.app.background_sync';

/// Periodic frequency. Android's WorkManager clamps to a minimum of 15
/// minutes; we ask for that. Doze and battery-saver may delay further.
const Duration kBackgroundSyncFrequency = Duration(minutes: 15);

/// Top-level entry point for the WorkManager isolate. Must stay top-level
/// and annotated `@pragma('vm:entry-point')` so the AOT tree-shaker
/// preserves it.
///
/// Inside this isolate there is no Riverpod scope, no Flutter widget tree
/// — every dependency is rebuilt from scratch by [BackgroundSyncRunner.run].
@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    developer.log(
      'WorkManager fired task=$task inputData=$inputData',
      name: 'starling.bgsync',
    );
    if (task != kBackgroundSyncTaskName) {
      // Unknown task name — return true so WorkManager doesn't endlessly
      // retry something we don't recognise. Phase D may add iOS-only
      // identifiers, but iOS BGTaskScheduler is handled natively, not
      // through this dispatcher.
      return true;
    }
    final outcome = await BackgroundSyncRunner.run(allowTor: false);
    switch (outcome) {
      case BackgroundSyncOutcome.ok:
      case BackgroundSyncOutcome.noIdentity:
        return true;
      case BackgroundSyncOutcome.failed:
        // Returning false asks WorkManager to retry per its
        // [BackoffPolicy]. Default is exponential starting at ~30s.
        return false;
    }
  });
}

/// Initialize WorkManager and (re-)register the periodic sync task. Idempotent
/// and safe to call on every resume. Only does anything on Android — iOS
/// schedules through BGTaskScheduler in [Phase D].
Future<void> initializeBackgroundSync() async {
  if (!Platform.isAndroid) return;
  try {
    await Workmanager().initialize(
      backgroundSyncCallbackDispatcher,
      // ignore: prefer_const_constructors
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      kBackgroundSyncTaskName,
      kBackgroundSyncTaskName,
      frequency: kBackgroundSyncFrequency,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
    developer.log(
      'WorkManager periodic task registered name=$kBackgroundSyncTaskName '
      'freq=${kBackgroundSyncFrequency.inMinutes}min',
      name: 'starling.bgsync',
    );
  } catch (e, st) {
    developer.log(
      'WorkManager init/register failed: $e\n$st',
      name: 'starling.bgsync',
    );
  }
}

/// Cancels the periodic task. Used when the foreground service is enabled
/// (Phase C) so we don't double-sync, and on uninstall paths.
Future<void> cancelBackgroundSync() async {
  if (!Platform.isAndroid) return;
  try {
    await Workmanager().cancelByUniqueName(kBackgroundSyncTaskName);
  } catch (_) {}
}
