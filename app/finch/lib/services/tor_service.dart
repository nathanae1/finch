import 'types.dart';

/// Abstract interface for Tor (Arti) operations.
///
/// Default implementation wraps Arti via Rust FFI (Plan 11).
/// Mock implementation simulates bootstrap and connections.
abstract class TorService {
  Future<void> init(String dataDir);

  Future<String> createOnionService(int localPort);

  Future<PeerConnection> connectToOnion(String address, int port);

  TorStatus getStatus();

  Future<void> shutdown();

  /// Cached `.onion` address from the most recent successful
  /// [createOnionService] call, or `null` if the service hasn't been
  /// published yet (or after [shutdown]).
  String? get onionAddress;

  /// Local TCP port of the in-process SOCKS5 proxy. Returns `0` until the
  /// listener is bound (i.e. before [init] completes).
  int get socksPort;

  /// Convenience: Tor is bootstrapped *and* a SOCKS proxy is listening.
  bool get isReady;
}
