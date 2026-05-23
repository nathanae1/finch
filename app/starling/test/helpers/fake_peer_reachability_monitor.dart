import 'dart:async';

import 'package:starling/models/connection_card.dart';
import 'package:starling/services/types.dart';
import 'package:starling/sync/peer_reachability_monitor.dart';

/// In-memory stand-in for [PeerReachabilityMonitor]. Tests pre-seed the
/// `(pubkey, transport)` -> baseUrl map so `bestConnectionFor` and
/// `probeCard` deterministically return the expected `PeerConnection`
/// without spinning up the real probe machinery.
class FakePeerReachabilityMonitor implements PeerReachabilityMonitor {
  final Map<String, Map<PeerTransport, String>> _reachable = {};
  final List<({String pubkey, PeerTransport transport, Object reason})>
      markedUnreachable = [];

  void setReachable(String pubkey, PeerTransport transport, String baseUrl) {
    _reachable.putIfAbsent(pubkey, () => {})[transport] = baseUrl;
  }

  void clear() => _reachable.clear();

  @override
  Future<PeerConnection?> bestConnectionFor(String pubkey) async {
    final tier = _reachable[pubkey];
    if (tier == null) return null;
    for (final transport in [PeerTransport.lan, PeerTransport.tor]) {
      final url = tier[transport];
      if (url != null) {
        return PeerConnection(
          pubkey: pubkey,
          baseUrl: url,
          transport: transport,
        );
      }
    }
    return null;
  }

  @override
  Future<PeerConnection?> probeCard(ConnectionCard card) =>
      bestConnectionFor(card.pubkey);

  @override
  void markUnreachable(String pubkey, PeerTransport transport, Object reason) {
    markedUnreachable
        .add((pubkey: pubkey, transport: transport, reason: reason));
    _reachable[pubkey]?.remove(transport);
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> refreshNow() async {}

  @override
  Stream<Map<String, PeerReachability>> get stateStream =>
      const Stream<Map<String, PeerReachability>>.empty();

  @override
  Map<String, PeerReachability> get state => const {};
}
