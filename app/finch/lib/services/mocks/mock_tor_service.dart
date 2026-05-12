import '../tor_service.dart';
import '../types.dart';

/// Simulated TorService for testing without a real Tor client.
class MockTorService implements TorService {
  bool _isReady = false;
  String? _onionAddress;

  @override
  Future<void> init(String dataDir) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isReady = true;
  }

  @override
  Future<String> createOnionService(int localPort) async {
    _onionAddress = 'mockabcdef1234567890abcdef1234567890abcdef12345678.onion';
    return _onionAddress!;
  }

  @override
  Future<PeerConnection> connectToOnion(String address, int port) async {
    return PeerConnection(
      pubkey: 'mock-peer',
      baseUrl: 'http://$address:$port',
      transport: PeerTransport.tor,
    );
  }

  @override
  TorStatus getStatus() => TorStatus(
        bootstrapPercent: _isReady ? 100 : 0,
        circuitCount: _isReady ? 3 : 0,
        isReady: _isReady,
        onionAddress: _onionAddress,
      );

  @override
  Future<void> shutdown() async {
    _isReady = false;
    _onionAddress = null;
  }

  @override
  String? get onionAddress => _onionAddress;

  @override
  int get socksPort => _isReady ? 9999 : 0;

  @override
  bool get isReady => _isReady;
}
