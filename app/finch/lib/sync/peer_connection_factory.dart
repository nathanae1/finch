import '../services/mdns_service.dart';
import '../services/types.dart';

/// Resolves a [PeerConnection] for a follow's pubkey by consulting the
/// live mDNS peer cache.
///
/// Plans 11/15 will add Tor + relay tiers. The factory will then try LAN
/// first (lowest latency), then onion, then relay — see
/// `protocol-spec.md` "Sync Protocol".
class PeerConnectionFactory {
  PeerConnectionFactory({required MdnsService mdns}) : _mdns = mdns;

  final MdnsService _mdns;

  /// Returns a `PeerConnection` for [pubkey] if a LAN peer is currently
  /// visible, or `null` if none is reachable.
  PeerConnection? buildLanConnection(String pubkey) {
    final peer = _mdns.currentPeers()[pubkey];
    if (peer == null) return null;
    return PeerConnection(
      pubkey: pubkey,
      baseUrl: 'http://${peer.host}:${peer.port}',
      transport: PeerTransport.lan,
    );
  }
}
