import 'dart:async';

import '../mdns_service.dart';
import '../types.dart';

/// In-memory `MdnsService` for tests. Tests can drive the cache by calling
/// [setPeers] / [removePeer]; the broadcast stream emits each change.
class MockMdnsService implements MdnsService {
  final Map<String, LanPeer> _cache = {};
  final StreamController<Map<String, LanPeer>> _controller =
      StreamController<Map<String, LanPeer>>.broadcast();
  bool _running = false;

  bool get isRegistered => _running;
  String? lastPubkey;
  int? lastPort;
  int rescanCount = 0;

  @override
  Future<void> register({required String pubkey, required int port}) async {
    _running = true;
    lastPubkey = pubkey;
    lastPort = port;
  }

  @override
  Future<void> deregister() async {
    _running = false;
    if (_cache.isNotEmpty) {
      _cache.clear();
      _controller.add(Map.unmodifiable(_cache));
    }
  }

  @override
  Stream<Map<String, LanPeer>> get peers => _controller.stream;

  @override
  Map<String, LanPeer> currentPeers() => Map.unmodifiable(_cache);

  @override
  Future<void> rescan() async {
    rescanCount++;
  }

  // --- Test helpers ---

  void setPeer(LanPeer peer) {
    _cache[peer.pubkey] = peer;
    _controller.add(Map.unmodifiable(_cache));
  }

  void removePeer(String pubkey) {
    if (_cache.remove(pubkey) != null) {
      _controller.add(Map.unmodifiable(_cache));
    }
  }

  Future<void> dispose() => _controller.close();
}
