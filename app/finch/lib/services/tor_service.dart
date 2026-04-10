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
}
