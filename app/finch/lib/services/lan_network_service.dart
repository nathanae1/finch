import 'dart:async';
import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../sync/sync_engine.dart' show SyncTransport;
import 'mdns_service.dart';
import 'network_service.dart';
import 'types.dart';

/// Concrete `NetworkService` for LAN sync (Plan 09). Wraps the bespoke
/// mDNS plugin for discovery and `package:http` for the manifest / events
/// / media fetches.
///
/// Tor and relay tiers (Plans 11 and 15) will land alongside this as
/// additional `PeerTransport` enum branches. The current implementation
/// rejects non-LAN transports because it has no way to dial them.
class LanNetworkService implements NetworkService, SyncTransport {
  LanNetworkService({
    required MdnsService mdns,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  })  : _mdns = mdns,
        _http = httpClient ?? http.Client(),
        _timeout = timeout;

  final MdnsService _mdns;
  final http.Client _http;
  final Duration _timeout;

  // --- Discovery ---

  @override
  Future<Map<String, LanPeer>> discoverLanPeers() async => _mdns.currentPeers();

  @override
  Future<void> registerMdns(String pubkey, int port) =>
      _mdns.register(pubkey: pubkey, port: port);

  @override
  Future<void> deregisterMdns() => _mdns.deregister();

  // --- Peer connections ---

  @override
  Future<PeerConnection> connectToPeer(ConnectionCard connectionCard) async {
    // The connection card is the handshake-time contact card. For LAN sync
    // the live peer cache is authoritative, not the card. Higher layers
    // (Plan 11/15) will pick onion / relay endpoints from the card here.
    throw UnimplementedError(
      'LanNetworkService.connectToPeer is not used by Plan 09 sync — '
      'callers should resolve a LanPeer via the discovery cache and build '
      'a PeerConnection directly. See PeerConnectionFactory.',
    );
  }

  // --- Sync HTTP fetches ---

  @override
  Future<Manifest> fetchManifest(
    PeerConnection connection, {
    int? since,
    int? until,
  }) async {
    _requireLan(connection);
    final query = <String, String>{};
    if (since != null) query['since'] = since.toString();
    if (until != null) query['until'] = until.toString();
    final uri = Uri.parse('${connection.baseUrl}/manifest')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await _http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw NetworkException(
        'manifest fetch failed: ${res.statusCode}',
        connection.pubkey,
      );
    }
    final decoded = cbor.decode(res.bodyBytes);
    if (decoded is! Map) {
      throw NetworkException('manifest body not a CBOR map', connection.pubkey);
    }
    final events = (decoded['events'] as List<dynamic>? ?? const [])
        .map((e) => e as Map<dynamic, dynamic>)
        .map((e) => ManifestEntry(
              id: e['id'] as String,
              createdAt: e['created_at'] as int,
            ))
        .toList();
    return Manifest(
      pubkey: decoded['pubkey'] as String,
      events: events,
      hasOlder: (decoded['has_older'] as bool?) ?? false,
    );
  }

  @override
  Future<List<EncryptedEvent>> fetchEvents(
    PeerConnection connection, {
    int? since,
  }) async {
    _requireLan(connection);
    final query = <String, String>{};
    if (since != null) query['since'] = since.toString();
    final uri = Uri.parse('${connection.baseUrl}/events')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await _http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw NetworkException(
        'events fetch failed: ${res.statusCode}',
        connection.pubkey,
      );
    }
    final envelope = Envelope.fromBytes(res.bodyBytes);
    final out = <EncryptedEvent>[];
    for (final item in envelope.items) {
      if (item.type == 'event') {
        out.add(EncryptedEvent.fromBytes(item.payload));
      }
      // Unknown item types are ignored at this layer; the sync engine
      // pulls them from the envelope directly via fetchEnvelope().
    }
    return out;
  }

  /// Variant of [fetchEvents] that returns the raw `Envelope` so callers
  /// can route unknown item types into opaque storage. This is the entry
  /// point used by the sync engine via [SyncTransport].
  @override
  Future<Envelope> fetchEnvelope(
    PeerConnection connection, {
    int? since,
  }) async {
    _requireLan(connection);
    final query = <String, String>{};
    if (since != null) query['since'] = since.toString();
    final uri = Uri.parse('${connection.baseUrl}/events')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await _http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw NetworkException(
        'events fetch failed: ${res.statusCode}',
        connection.pubkey,
      );
    }
    return Envelope.fromBytes(res.bodyBytes);
  }

  @override
  Future<Uint8List> fetchMedia(PeerConnection connection, String hash) async {
    _requireLan(connection);
    final uri = Uri.parse('${connection.baseUrl}/media/$hash');
    final res = await _http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw NetworkException(
        'media fetch failed: ${res.statusCode}',
        connection.pubkey,
      );
    }
    return res.bodyBytes;
  }

  // --- Follow operations (Plan 08 wiring runs through FollowService directly,
  // but Plan 11+ will call these from the relay/Tor tier). ---

  @override
  Future<void> sendFollowRequest(
    PeerConnection connection,
    Uint8List requestPayload,
  ) async {
    final uri = Uri.parse('${connection.baseUrl}/follow-request');
    final res = await _http
        .post(uri, headers: const {'content-type': 'application/cbor'},
            body: requestPayload)
        .timeout(_timeout);
    if (res.statusCode != 202) {
      throw NetworkException(
        'follow-request failed: ${res.statusCode}',
        connection.pubkey,
      );
    }
  }

  @override
  Future<void> sendFollowAccept(
    PeerConnection connection,
    Uint8List acceptPayload,
  ) async {
    final uri = Uri.parse('${connection.baseUrl}/follow-accept');
    final res = await _http
        .post(uri, headers: const {'content-type': 'application/cbor'},
            body: acceptPayload)
        .timeout(_timeout);
    if (res.statusCode != 202) {
      throw NetworkException(
        'follow-accept failed: ${res.statusCode}',
        connection.pubkey,
      );
    }
  }

  // --- Push to relay (deferred to Plan 15) ---

  @override
  Future<void> pushEvents(
    PeerConnection connection,
    List<EncryptedEvent> events,
  ) async {
    throw UnimplementedError('pushEvents arrives in Plan 15 (relay).');
  }

  @override
  Future<void> pushMedia(
    PeerConnection connection,
    String hash,
    Uint8List blob,
  ) async {
    throw UnimplementedError('pushMedia arrives in Plan 15 (relay).');
  }

  void _requireLan(PeerConnection connection) {
    if (connection.transport != PeerTransport.lan) {
      throw NetworkException(
        'LanNetworkService only handles PeerTransport.lan, got '
        '${connection.transport}',
        connection.pubkey,
      );
    }
  }

  /// Closes the underlying HTTP client. Tests should call this in tearDown
  /// when the service was constructed without an injected client.
  void close() => _http.close();
}

class NetworkException implements Exception {
  const NetworkException(this.message, this.peerPubkey);
  final String message;
  final String peerPubkey;
  @override
  String toString() => 'NetworkException($peerPubkey): $message';
}
