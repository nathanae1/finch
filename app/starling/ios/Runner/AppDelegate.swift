import BackgroundTasks
import Flutter
import UIKit

private let kBackgroundSyncIdentifier = "dev.starling.app.background_sync"
private let kBackgroundProcessingIdentifier = "dev.starling.app.background_processing"
private let kBackgroundChannelName = "dev.starling.app/background_sync"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var backgroundChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerBackgroundTasks()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QrScannerPlugin") {
      QrScannerPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MdnsPlugin") {
      MdnsPlugin.register(with: registrar)
    }
    // Flutter 3.x exposes the engine's binary messenger via the
    // `applicationRegistrar` on the implicit-engine bridge, not directly
    // on the bridge itself. (`engineBridge.binaryMessenger` was removed.)
    let messenger = engineBridge.applicationRegistrar.messenger()
    backgroundChannel = FlutterMethodChannel(
      name: kBackgroundChannelName,
      binaryMessenger: messenger
    )
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    scheduleBackgroundTasks()
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    // Plan 14 Phase D — pre-refresh the Tor consensus before iOS suspends
    // us, so the next BGProcessingTask wake finds a fresh phonebook on
    // disk and warm-bootstrap stays under the 10s budget. Fire-and-forget;
    // iOS gives ~5s of background time after this callback before
    // suspension.
    backgroundChannel?.invokeMethod("refreshTorDirectory", arguments: nil)
  }

  // MARK: - BGTaskScheduler

  private func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: kBackgroundSyncIdentifier,
      using: nil
    ) { [weak self] task in
      self?.handleAppRefreshTask(task: task as! BGAppRefreshTask)
    }
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: kBackgroundProcessingIdentifier,
      using: nil
    ) { [weak self] task in
      self?.handleProcessingTask(task: task as! BGProcessingTask)
    }
  }

  private func scheduleBackgroundTasks() {
    // App refresh: ~30s budget, LAN-only sync.
    let refresh = BGAppRefreshTaskRequest(identifier: kBackgroundSyncIdentifier)
    refresh.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    do {
      try BGTaskScheduler.shared.submit(refresh)
    } catch {
      NSLog("[starling.bg] failed to submit BGAppRefreshTask: \(error)")
    }

    // Processing: long window when plugged in + idle, Tor warm-bootstrap.
    let processing = BGProcessingTaskRequest(identifier: kBackgroundProcessingIdentifier)
    processing.requiresNetworkConnectivity = true
    processing.requiresExternalPower = true
    processing.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
    do {
      try BGTaskScheduler.shared.submit(processing)
    } catch {
      NSLog("[starling.bg] failed to submit BGProcessingTask: \(error)")
    }
  }

  private func handleAppRefreshTask(task: BGAppRefreshTask) {
    NSLog("[starling.bg] BGAppRefreshTask fired")
    // Re-submit next request first so a failure here doesn't break the
    // recurring schedule.
    scheduleAppRefresh()

    task.expirationHandler = {
      NSLog("[starling.bg] BGAppRefreshTask expiration handler — bailing")
      task.setTaskCompleted(success: false)
    }

    invokeDartBackgroundSync(allowTor: false) { success in
      task.setTaskCompleted(success: success)
    }
  }

  private func handleProcessingTask(task: BGProcessingTask) {
    NSLog("[starling.bg] BGProcessingTask fired")
    scheduleProcessing()

    task.expirationHandler = {
      NSLog("[starling.bg] BGProcessingTask expiration handler — bailing")
      task.setTaskCompleted(success: false)
    }

    invokeDartBackgroundSync(allowTor: true) { success in
      task.setTaskCompleted(success: success)
    }
  }

  private func scheduleAppRefresh() {
    let refresh = BGAppRefreshTaskRequest(identifier: kBackgroundSyncIdentifier)
    refresh.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try? BGTaskScheduler.shared.submit(refresh)
  }

  private func scheduleProcessing() {
    let processing = BGProcessingTaskRequest(identifier: kBackgroundProcessingIdentifier)
    processing.requiresNetworkConnectivity = true
    processing.requiresExternalPower = true
    processing.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
    try? BGTaskScheduler.shared.submit(processing)
  }

  private func invokeDartBackgroundSync(
    allowTor: Bool,
    completion: @escaping (Bool) -> Void
  ) {
    guard let channel = backgroundChannel else {
      NSLog("[starling.bg] backgroundChannel not available — Dart engine not initialised")
      completion(false)
      return
    }
    channel.invokeMethod("runBackgroundSync", arguments: ["allowTor": allowTor]) { result in
      if let error = result as? FlutterError {
        NSLog("[starling.bg] Dart sync error: \(error.message ?? "")")
        completion(false)
      } else if let success = result as? Bool {
        completion(success)
      } else {
        NSLog("[starling.bg] Dart sync returned unexpected result: \(String(describing: result))")
        completion(false)
      }
    }
  }
}
