import AVFoundation
import Flutter
import UIKit

/// Bespoke QR scanner plugin (Plan 08). Avoids Google ML Kit / mobile_scanner
/// for product (no Play Services) and DX (arm64-sim slice) reasons. The
/// native code is intentionally narrow: detect a QR payload, hand the string
/// to Flutter, let the Dart layer drive UI and retry policy.
public class QrScannerPlugin: NSObject, FlutterPlugin {
  private static let methodChannelName = "dev.starling.qr_scanner"
  private static let eventChannelName = "dev.starling.qr_scanner/scans"
  private static let viewType = "dev.starling.qr_scanner_view"

  private let session = AVCaptureSession()
  private let metadataOutput = AVCaptureMetadataOutput()
  private let metadataDelegate = QrMetadataDelegate()
  private var sessionConfigured = false
  private var sessionQueue = DispatchQueue(label: "dev.starling.qr_scanner.session")

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = QrScannerPlugin()

    let methodChannel = FlutterMethodChannel(
      name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: eventChannelName, binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance.metadataDelegate)

    let factory = QrScannerViewFactory(session: instance.session)
    registrar.register(factory, withId: viewType)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      requestPermissionAndStart(result: result)
    case "stop":
      sessionQueue.async {
        if self.session.isRunning {
          self.session.stopRunning()
        }
        DispatchQueue.main.async { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermissionAndStart(result: @escaping FlutterResult) {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      configureAndStart(result: result)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          if granted {
            self.configureAndStart(result: result)
          } else {
            result(
              FlutterError(
                code: "permission-denied",
                message: "Camera permission denied",
                details: nil))
          }
        }
      }
    default:
      result(
        FlutterError(
          code: "permission-denied",
          message: "Camera permission denied",
          details: nil))
    }
  }

  private func configureAndStart(result: @escaping FlutterResult) {
    sessionQueue.async {
      if !self.sessionConfigured {
        guard let device = AVCaptureDevice.default(for: .video) else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "camera-unavailable",
                message: "No video capture device",
                details: nil))
          }
          return
        }
        do {
          let input = try AVCaptureDeviceInput(device: device)
          self.session.beginConfiguration()
          if self.session.canAddInput(input) {
            self.session.addInput(input)
          }
          if self.session.canAddOutput(self.metadataOutput) {
            self.session.addOutput(self.metadataOutput)
          }
          self.metadataOutput.setMetadataObjectsDelegate(
            self.metadataDelegate, queue: DispatchQueue.main)
          if self.metadataOutput.availableMetadataObjectTypes.contains(.qr) {
            self.metadataOutput.metadataObjectTypes = [.qr]
          }
          self.session.commitConfiguration()
          self.sessionConfigured = true
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "camera-unavailable",
                message: "Could not open camera: \(error.localizedDescription)",
                details: nil))
          }
          return
        }
      }
      if !self.session.isRunning {
        self.session.startRunning()
      }
      DispatchQueue.main.async { result(nil) }
    }
  }
}

/// Forwards QR detections to the Flutter event-channel sink. Deduplicates
/// rapid identical reads (within 500ms) so a steady camera doesn't spam the
/// stream.
private class QrMetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate,
  FlutterStreamHandler
{
  private var sink: FlutterEventSink?
  private var lastPayload: String?
  private var lastEmittedAt: Date?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard let sink else { return }
    for object in metadataObjects {
      if let qr = object as? AVMetadataMachineReadableCodeObject,
        qr.type == .qr,
        let payload = qr.stringValue
      {
        let now = Date()
        if payload == lastPayload,
          let last = lastEmittedAt,
          now.timeIntervalSince(last) < 0.5
        {
          continue
        }
        lastPayload = payload
        lastEmittedAt = now
        sink(payload)
      }
    }
  }
}

/// PlatformViewFactory that vends a UIView hosting the live preview layer.
private class QrScannerViewFactory: NSObject, FlutterPlatformViewFactory {
  private let session: AVCaptureSession
  init(session: AVCaptureSession) { self.session = session }

  func create(
    withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
  ) -> FlutterPlatformView {
    return QrScannerPlatformView(frame: frame, session: session)
  }
}

private class QrScannerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let previewLayer: AVCaptureVideoPreviewLayer

  init(frame: CGRect, session: AVCaptureSession) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .black
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    super.init()
    previewLayer.frame = containerView.bounds
    containerView.layer.addSublayer(previewLayer)
    containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(layoutPreview),
      name: UIDevice.orientationDidChangeNotification,
      object: nil)
  }

  func view() -> UIView { return containerView }

  @objc private func layoutPreview() {
    previewLayer.frame = containerView.bounds
  }
}
