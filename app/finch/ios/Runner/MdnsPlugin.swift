import Flutter
import Foundation
import Network

/// Bespoke mDNS plugin (Plan 09). Advertises `_finch._tcp` via NWListener
/// and resolves peers via NWBrowser. Native code is intentionally narrow:
/// publish a service, browse for services, and emit `peer-found` /
/// `peer-lost` events to Dart. All policy (filter against follows, schedule
/// rescans, etc.) lives in Dart.
public class MdnsPlugin: NSObject, FlutterPlugin {
  private static let methodChannelName = "dev.finch.mdns"
  private static let eventChannelName = "dev.finch.mdns/peers"
  private static let serviceType = "_finch._tcp"

  private let queue = DispatchQueue(label: "dev.finch.mdns")
  private let streamHandler = MdnsStreamHandler()

  private var listener: NWListener?
  private var browser: NWBrowser?
  private var resolvers: [String: NWConnection] = [:]
  private var advertisedPubkey: String?
  private var advertisedPort: Int?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MdnsPlugin()

    let methodChannel = FlutterMethodChannel(
      name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: eventChannelName, binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance.streamHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "register":
      guard let args = call.arguments as? [String: Any],
        let pubkey = args["pubkey"] as? String,
        let port = args["port"] as? Int
      else {
        result(
          FlutterError(
            code: "invalid-args", message: "register requires pubkey + port",
            details: nil))
        return
      }
      queue.async { self.startAdvertise(pubkey: pubkey, port: port, result: result) }
    case "deregister":
      queue.async { self.tearDown(result: result) }
    case "rescan":
      queue.async { self.restartBrowse(result: result) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startAdvertise(pubkey: String, port: Int, result: @escaping FlutterResult) {
    tearDownInternal(emitCleared: false)
    advertisedPubkey = pubkey
    advertisedPort = port

    let txtRecord = NWTXTRecord([
      "pubkey": pubkey,
      "port": String(port),
    ])
    let service = NWListener.Service(
      name: pubkey, type: MdnsPlugin.serviceType, domain: nil, txtRecord: txtRecord)

    do {
      let params = NWParameters.tcp
      let l = try NWListener(service: service, using: params)
      l.newConnectionHandler = { conn in
        // We don't actually accept connections on this listener — the HTTP
        // server owns the data port. Reject incoming so the listener stays
        // healthy.
        conn.cancel()
      }
      l.stateUpdateHandler = { _ in }
      l.start(queue: queue)
      listener = l
    } catch {
      DispatchQueue.main.async {
        result(
          FlutterError(
            code: "advertise-failed",
            message: "NWListener init failed: \(error.localizedDescription)",
            details: nil))
      }
      return
    }

    startBrowseInternal()
    DispatchQueue.main.async { result(nil) }
  }

  private func startBrowseInternal() {
    let descriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(
      type: MdnsPlugin.serviceType, domain: nil)
    let params = NWParameters.tcp
    params.includePeerToPeer = true
    let b = NWBrowser(for: descriptor, using: params)
    b.browseResultsChangedHandler = { [weak self] results, changes in
      self?.handleBrowseResults(results: results, changes: changes)
    }
    b.stateUpdateHandler = { _ in }
    b.start(queue: queue)
    browser = b
  }

  private func restartBrowse(result: @escaping FlutterResult) {
    browser?.cancel()
    browser = nil
    streamHandler.send(["event": "cleared"])
    startBrowseInternal()
    DispatchQueue.main.async { result(nil) }
  }

  private func handleBrowseResults(
    results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>
  ) {
    for change in changes {
      switch change {
      case .added(let r):
        emitFound(result: r)
      case .changed(_, let r, _):
        emitFound(result: r)
      case .removed(let r):
        emitLost(result: r)
      case .identical:
        break
      @unknown default:
        break
      }
    }
  }

  private func emitFound(result: NWBrowser.Result) {
    let txt = txtRecord(from: result)
    guard let pubkey = txt["pubkey"], !pubkey.isEmpty,
      let portString = txt["port"], let port = Int(portString)
    else { return }
    if pubkey == advertisedPubkey { return }  // skip self

    // Resolve the endpoint to a host. NWBrowser yields a service endpoint;
    // we open a transient connection to learn its IP, then cancel it.
    let connection = NWConnection(to: result.endpoint, using: .tcp)
    let key = pubkey
    resolvers[key]?.cancel()
    resolvers[key] = connection
    connection.stateUpdateHandler = { [weak self] state in
      guard let self else { return }
      switch state {
      case .ready:
        if let host = self.hostFromConnection(connection) {
          self.streamHandler.send([
            "event": "peer-found",
            "pubkey": pubkey,
            "host": host,
            "port": port,
          ])
        }
        connection.cancel()
        self.resolvers.removeValue(forKey: key)
      case .failed, .cancelled:
        self.resolvers.removeValue(forKey: key)
      default:
        break
      }
    }
    connection.start(queue: queue)
  }

  private func emitLost(result: NWBrowser.Result) {
    let txt = txtRecord(from: result)
    guard let pubkey = txt["pubkey"] else { return }
    streamHandler.send([
      "event": "peer-lost",
      "pubkey": pubkey,
    ])
  }

  private func txtRecord(from result: NWBrowser.Result) -> [String: String] {
    if case let .bonjour(record) = result.metadata {
      var out: [String: String] = [:]
      for key in record.dictionary.keys {
        if let value = record[key] {
          out[key] = value
        }
      }
      return out
    }
    return [:]
  }

  private func hostFromConnection(_ connection: NWConnection) -> String? {
    guard let endpoint = connection.currentPath?.remoteEndpoint else { return nil }
    switch endpoint {
    case .hostPort(let host, _):
      return hostString(host)
    default:
      return nil
    }
  }

  private func hostString(_ host: NWEndpoint.Host) -> String {
    switch host {
    case .ipv4(let addr):
      return ipv4String(addr)
    case .ipv6(let addr):
      return ipv6String(addr)
    case .name(let name, _):
      return name
    @unknown default:
      return ""
    }
  }

  private func ipv4String(_ addr: IPv4Address) -> String {
    let bytes = addr.rawValue
    return "\(bytes[0]).\(bytes[1]).\(bytes[2]).\(bytes[3])"
  }

  private func ipv6String(_ addr: IPv6Address) -> String {
    let bytes = addr.rawValue
    var parts: [String] = []
    for i in stride(from: 0, to: 16, by: 2) {
      let part = (UInt16(bytes[i]) << 8) | UInt16(bytes[i + 1])
      parts.append(String(part, radix: 16))
    }
    return parts.joined(separator: ":")
  }

  private func tearDown(result: @escaping FlutterResult) {
    tearDownInternal(emitCleared: true)
    DispatchQueue.main.async { result(nil) }
  }

  private func tearDownInternal(emitCleared: Bool) {
    listener?.cancel()
    listener = nil
    browser?.cancel()
    browser = nil
    for (_, conn) in resolvers { conn.cancel() }
    resolvers.removeAll()
    advertisedPubkey = nil
    advertisedPort = nil
    if emitCleared {
      streamHandler.send(["event": "cleared"])
    }
  }
}

private class MdnsStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

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

  func send(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.sink?(payload)
    }
  }
}
