import 'dart:typed_data';

import '../models/models.dart';
import '../services/types.dart';
import 'sync_engine.dart' show SyncTransport;

/// Dispatches each [SyncTransport] call to the underlying transport for
/// `connection.transport`. Plan 11b uses two backings:
///   - LAN: `LanNetworkService` with a default `http.Client`
///   - Tor: `LanNetworkService` with a `TorHttpClient` (SOCKS5 → Arti)
///
/// The wire-level code is identical (HTTP/1.1 to a Starling peer); only the
/// dialer differs.
class TransportRouter implements SyncTransport {
  TransportRouter({
    required SyncTransport lan,
    required SyncTransport tor,
  })  : _lan = lan,
        _tor = tor;

  final SyncTransport _lan;
  final SyncTransport _tor;

  SyncTransport _pick(PeerConnection peer) =>
      peer.transport == PeerTransport.tor ? _tor : _lan;

  @override
  Future<Manifest> fetchManifest(
    PeerConnection peer, {
    int? since,
    int? until,
    String? requesterPubkey,
    int? ackRotationAt,
  }) =>
      _pick(peer).fetchManifest(
        peer,
        since: since,
        until: until,
        requesterPubkey: requesterPubkey,
        ackRotationAt: ackRotationAt,
      );

  @override
  Future<Envelope> fetchEnvelope(PeerConnection peer, {int? since}) =>
      _pick(peer).fetchEnvelope(peer, since: since);

  @override
  Future<Uint8List> fetchMedia(PeerConnection peer, String hash) =>
      _pick(peer).fetchMedia(peer, hash);

  @override
  Future<void> pushEnvelope(PeerConnection peer, Envelope envelope) =>
      _pick(peer).pushEnvelope(peer, envelope);
}
