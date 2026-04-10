import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';

import '../../models/models.dart';
import '../../server/handlers/signaling_handler.dart';
import '../crypto_service.dart';
import '../network_service.dart';
import '../signaling_service.dart';
import '../types.dart';

/// WebSocket-based [SignalingService] implementation.
///
/// Outbound connections: opens a WebSocket to the peer's `/ws/signal`
/// endpoint (resolved via [NetworkService.connectToPeer]) with Ed25519
/// auth headers.
///
/// Inbound connections: handled by [signalingHandler] on the shelf server,
/// which calls [_inboundHandler] for each authenticated connection.
class WsSignalingService implements SignalingService {
  WsSignalingService({
    required this.crypto,
    required this.network,
    required this.localPubkey,
    required this.localSecretKey,
  });

  final CryptoService crypto;
  final NetworkService network;

  /// Our Ed25519 public key (base64-encoded).
  final String localPubkey;

  /// Our Ed25519 secret key (for signing auth headers).
  final Uint8List localSecretKey;

  final Map<String, SignalingChannel> _channels = {};
  void Function(SignalingChannel channel)? _inboundHandler;

  @override
  Future<SignalingChannel> connect(ConnectionCard peer) async {
    // If we already have an open channel to this peer, return it.
    final existing = _channels[peer.pubkey];
    if (existing != null && existing.isOpen) return existing;

    // Resolve the peer's base URL via NetworkService.
    final peerConn = await network.connectToPeer(peer);

    // Build the WebSocket URL from the peer's HTTP base URL.
    final httpUri = Uri.parse(peerConn.baseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = httpUri.replace(
      scheme: wsScheme,
      path: '/ws/signal',
    );

    // Generate auth headers.
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final message = 'websocket-upgrade$timestamp';
    final sig = crypto.sign(
      localSecretKey,
      Uint8List.fromList(utf8.encode(message)),
    );

    // Connect with auth headers.
    // IOWebSocketChannel supports custom headers on the upgrade request.
    final webSocket = IOWebSocketChannel.connect(
      wsUri,
      headers: {
        'X-Finch-Pubkey': localPubkey,
        'X-Finch-Sig': base64.encode(sig),
        'X-Finch-Timestamp': timestamp,
      },
    );

    // Wait for the connection to be established.
    await webSocket.ready;

    final channel = WebSocketSignalingChannel(
      remotePubkey: peer.pubkey,
      transport: peerConn.transport,
      webSocket: webSocket,
    );

    _channels[peer.pubkey] = channel;

    // Clean up when the channel closes.
    channel.messages.listen(null, onDone: () {
      _channels.remove(peer.pubkey);
    });

    return channel;
  }

  @override
  void onInboundConnection(
    void Function(SignalingChannel channel) handler,
  ) {
    _inboundHandler = handler;
  }

  /// Called by the server's signaling handler when an authenticated
  /// inbound WebSocket connection is established.
  void handleInbound(SignalingChannel channel) {
    _channels[channel.remotePubkey] = channel;

    // Clean up when the channel closes.
    channel.messages.listen(null, onDone: () {
      _channels.remove(channel.remotePubkey);
    });

    _inboundHandler?.call(channel);
  }

  @override
  Future<void> closeAll() async {
    final channels = List<SignalingChannel>.from(_channels.values);
    _channels.clear();
    for (final channel in channels) {
      await channel.close();
    }
  }

  @override
  Map<String, SignalingChannel> get activeChannels =>
      Map.unmodifiable(_channels);
}
