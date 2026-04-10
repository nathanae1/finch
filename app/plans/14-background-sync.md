# Plan 14: Background Sync & Platform Integration

## Dependencies
Plan 09 (sync engine), Plan 11 (Tor — needs lifecycle management)

## Scope

Keep content flowing when the app isn't in the foreground. Platform-specific background execution.

### Android WorkManager
- `workmanager` Flutter package
- Register periodic task: minimum 15-minute interval (Android-enforced minimum)
- Task runs sync engine in background:
  1. Initialize services (DB, crypto, feed key cache)
  2. Run abbreviated sync: discover LAN peers + try Tor endpoints
  3. Pull missing events, decrypt, store
  4. Shut down
- Subject to Doze mode: may be delayed when device is idle. Acceptable.
- No Tor bootstrap in background sync (too slow, 10-30s). Only use Tor if already bootstrapped. LAN + relay (Plan 15) are the primary background paths.

### Android foreground service (opt-in)
- `flutter_foreground_task` package
- User toggle in Settings: "Keep server running in background"
- When enabled:
  - Persistent notification: "Finch is running" (minimal, non-alarming)
  - HTTP server stays alive
  - Tor stays bootstrapped and onion service remains reachable
  - Device acts as a near-relay (always reachable by friends)
- When disabled: server and Tor stop on background
- Battery impact warning in UI

### iOS Background App Refresh
- Register for BAR in AppDelegate
- When iOS grants time (~30 seconds, unreliable timing):
  - Run abbreviated sync (LAN discovery + quick manifest check)
  - No Tor bootstrap (too slow for 30s window)
- This is best-effort only. Document clearly: iOS background sync is unreliable.
- Primary sync path on iOS remains app-open.

### App lifecycle management
Centralized lifecycle handler:

**On resume (foreground):**
1. Restart HTTP server (bind port)
2. Re-register mDNS
3. Bootstrap Tor (if enabled)
4. Trigger full sync
5. Reload feed key cache

**On pause (background):**
- **iOS**: stop HTTP server, deregister mDNS, shutdown Tor. No choice — iOS kills background processes.
- **Android (no foreground service)**: same as iOS — stop everything.
- **Android (foreground service active)**: keep running. HTTP server, mDNS, Tor all persist.

**On terminate:**
- Clear feed key cache from memory
- Clean shutdown of all services

### Network status screen (Settings)
- Per-peer status: pubkey, display name, last synced, connection type (LAN/Tor/relay), reachable now?
- Overall sync stats: total events synced, last sync time, next background sync (Android)
- Tor status: bootstrap %, circuit count, onion address
- Current server port

## Files created/modified
- `lib/services/background/workmanager_sync.dart`
- `lib/services/background/foreground_service.dart`
- `lib/services/background/ios_background_refresh.dart`
- `lib/services/lifecycle_manager.dart`
- `lib/screens/settings/network_status_screen.dart`
- `lib/providers/lifecycle_provider.dart`
- `lib/main.dart` (update: lifecycle hooks)
- `android/app/src/main/AndroidManifest.xml` (update: foreground service permission, FOREGROUND_SERVICE type)
- `ios/Runner/Info.plist` (update: UIBackgroundModes for fetch)
- `ios/Runner/AppDelegate.swift` (update: BAR registration)
- `pubspec.yaml` (add `workmanager`, `flutter_foreground_task`)
- `test/services/lifecycle_manager_test.dart`

## Verification
- **Android WorkManager**: background app, wait 15+ minutes, re-open → new content from friends appeared
- **Android foreground service**: toggle on → notification appears → background app → Tor still reachable (test from another device) → server still responds to HTTP requests
- **Android foreground service off**: background app → Tor unreachable, server unresponsive (expected)
- **iOS BAR**: register → use Xcode "Simulate Background Fetch" → verify sync ran (check logs / DB timestamps)
- **Resume**: background → foreground → sync triggers immediately, server restarts, Tor re-bootstraps
- **Terminate**: force-kill app → relaunch → clean state, no orphaned resources
- **Network status screen**: shows accurate per-peer info, Tor status, server port
- **Foreground service notification**: appears/disappears correctly with toggle

## Key decisions
- No Tor bootstrap in Android WorkManager or iOS BAR — too slow for the limited time window. Background sync uses LAN and relay only.
- Foreground service is opt-in with battery warning. Don't enable by default — users should understand the trade-off.
- WorkManager 15-minute minimum is Android-enforced. Can't go lower.
- `flutter_foreground_task` handles the notification and service lifecycle. Don't roll custom platform channels for this.

## Risks
- Android 14+ further restricts background work and foreground service types. Must declare correct `foregroundServiceType` (likely `dataSync`). Test on latest Android versions.
- iOS BAR is notoriously unreliable. Apple throttles apps that use too much background time. Do not depend on it for correctness — it's a nice-to-have bonus.
- Foreground service battery impact will generate user complaints if not clearly communicated. Show estimated battery impact in the toggle UI.
- WorkManager isolate doesn't have access to Flutter engine state. Must reinitialize services from scratch in the background task. Keep the initialization fast.
