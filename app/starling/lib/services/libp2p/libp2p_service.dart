import 'dart:async';
import 'dart:typed_data';

/// Abstract interface for libp2p (rust-libp2p + DCUtR) operations.
///
/// Plan 11a — direct-connect transport tier. Default implementation wraps
/// rust-libp2p via Rust FFI (mirroring the `arti_bridge` shape). A mock
/// implementation supports unit tests and the loopback-integration harness
/// (two bridges in one process dialing each other on 127.0.0.1).
///
/// Lifecycle: [init] is cheap (constructs the FFI handle); [listen] binds a
/// UDP socket and starts the swarm event loop — defer until first foreground
/// sync to save battery. [shutdown] tears the loop down on background.
///
/// Identity: [init] takes the Ed25519 *seed* (32 bytes — extract via
/// libsodium `crypto_sign_ed25519_sk_to_seed` from the stored 64-byte
/// expanded secret). The bridge copies the seed into Rust, constructs the
/// PeerId via `Keypair::ed25519_from_bytes`, and zeroizes its copy. Callers
/// MUST zeroize their Dart-side buffer immediately after [init] returns.
abstract class Libp2pService {
  /// Construct the Swarm with a PeerId derived from [ed25519Seed].
  /// [dataDir] holds the libp2p PeerStore caches (no secrets).
  Future<void> init(String dataDir, Uint8List ed25519Seed);

  /// Bind UDP listeners on `/ip4/0.0.0.0/udp/0/quic-v1` and start the swarm
  /// event loop. Idempotent — re-calling on an already-listening service is
  /// a no-op.
  Future<void> listen();

  /// Current candidate external addresses (multiaddr bytes) collected from
  /// STUN reflections, Identify "observed_addr" pings, and local listen
  /// addresses. Used to populate the `libp2p-connect-v1` signaling message
  /// the upgrader sends over Tor.
  Future<List<Uint8List>> observedAddrs();

  /// Inject an external address learned out-of-band (e.g., from the peer's
  /// observation during a signaling round-trip).
  Future<void> addObservedAddr(Uint8List multiaddr);

  /// Issue a DCUtR-aware direct dial against [remotePeerId] using
  /// [remoteAddrs] as candidate paths. Returns when the connection is
  /// established; throws [Libp2pDialException] on timeout, hole-punch
  /// failure, or remote rejection. The bridge tracks the resulting
  /// connection internally — subsequent [openStream] calls re-use it.
  Future<void> dialDirect(
    String remotePeerId,
    List<Uint8List> remoteAddrs, {
    Duration timeout = const Duration(seconds: 8),
  });

  /// Open a libp2p stream for [protocol] to [remotePeerId] over the
  /// connection the bridge already holds. Throws
  /// [Libp2pStreamException] if there is no established connection (the
  /// upgrader must call [dialDirect] first).
  Future<Libp2pStream> openStream(String remotePeerId, String protocol);

  /// Register a handler for inbound streams of [protocol]. The handler is
  /// invoked with each new stream; it owns reading/writing the request and
  /// closing the stream. The shelf-side equivalents in `lib/server/handlers/`
  /// are refactored to delegate to pure CBOR-in/CBOR-out functions so the
  /// libp2p handlers reuse the same business logic.
  void registerInboundHandler(
    String protocol,
    void Function(Libp2pStream stream) handler,
  );

  /// Broadcast stream of Swarm-level events (peer connected / disconnected,
  /// Identify exchange complete, DCUtR upgrade success/failure, observed
  /// address changed). Consumed by [Libp2pUpgrader] and the reachability
  /// monitor's libp2p probe loop.
  Stream<Libp2pEvent> get events;

  /// Whether the bridge has been initialized AND is currently listening on
  /// at least one transport. False during cold start, after [shutdown], or
  /// when the bridge has been disabled after repeated panics.
  bool get isReady;

  /// The local PeerId (base58 multihash of the Ed25519 public key). Empty
  /// until [init] has completed.
  String get localPeerId;

  /// Stop the swarm event loop and close all listeners. Outstanding
  /// connections are torn down. Mirror Arti's shutdown semantics: synchronous
  /// from the caller's perspective (the underlying tokio runtime drains).
  Future<void> shutdown();
}

/// A single libp2p stream. Length-delimited framing — each `write` and
/// `read` is one CBOR message.
abstract class Libp2pStream {
  /// Remote PeerId this stream is talking to.
  String get remotePeerId;

  /// Protocol negotiated for this stream (e.g. `/starling/sync/manifest/1`).
  String get protocol;

  /// Write one CBOR-encoded message. If [finish] is true, half-closes the
  /// stream after the frame (signals "no more requests" to the responder).
  Future<void> write(Uint8List data, {bool finish = false});

  /// Read one CBOR-encoded message. Throws [Libp2pStreamException] on
  /// timeout, stream reset, or remote close before any data arrived.
  Future<Uint8List> read({Duration? timeout});

  /// Close this stream. Idempotent.
  Future<void> close();
}

/// Swarm-level event emitted by the bridge.
sealed class Libp2pEvent {
  const Libp2pEvent();
}

class Libp2pPeerConnected extends Libp2pEvent {
  const Libp2pPeerConnected({required this.peerId});
  final String peerId;
}

class Libp2pPeerDisconnected extends Libp2pEvent {
  const Libp2pPeerDisconnected({required this.peerId});
  final String peerId;
}

class Libp2pIdentifyReceived extends Libp2pEvent {
  const Libp2pIdentifyReceived({
    required this.peerId,
    required this.observedAddr,
    required this.listenAddrs,
  });
  final String peerId;
  final Uint8List observedAddr;
  final List<Uint8List> listenAddrs;
}

// Plan 11c removed `Libp2pDcutrSucceeded` / `Libp2pDcutrFailed`: the
// `dcutr` libp2p behaviour was dropped (it requires a circuit-relay-v2
// client to fire, which Starling explicitly does not ship). The bridge
// no longer emits these events.

class Libp2pObservedAddrChanged extends Libp2pEvent {
  const Libp2pObservedAddrChanged({required this.multiaddr});
  final Uint8List multiaddr;
}

/// Thrown when [Libp2pService.dialDirect] cannot establish a connection
/// within the timeout — hole-punch failure, NAT incompatibility, peer
/// offline, etc. Callers fall back to Tor on this exception.
class Libp2pDialException implements Exception {
  const Libp2pDialException(this.message);
  final String message;
  @override
  String toString() => 'Libp2pDialException: $message';
}

/// Thrown by [Libp2pStream.read] / [Libp2pStream.write] when the underlying
/// stream is reset, timed out, or closed unexpectedly. The sync engine
/// catches this, marks the peer's `libp2pDirect` transport unreachable, and
/// proceeds on Tor next pump cycle.
class Libp2pStreamException implements Exception {
  const Libp2pStreamException(this.message);
  final String message;
  @override
  String toString() => 'Libp2pStreamException: $message';
}

/// Thrown by any [Libp2pService] method when the bridge has not been
/// initialized or has been disabled (e.g., after repeated FFI panics). The
/// router catches this and routes the call to Tor.
class Libp2pUnavailableException implements Exception {
  const Libp2pUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'Libp2pUnavailableException: $message';
}
