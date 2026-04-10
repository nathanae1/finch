import 'dart:async';
import 'dart:typed_data';

import '../../models/models.dart';
import '../signaling_service.dart';
import '../types.dart';

/// In-memory mock SignalingService for testing without real WebSockets.
///
/// Channels are connected in-memory: calling [connect] returns a channel
/// whose [send] delivers directly to the paired channel's [messages] stream.
class MockSignalingService implements SignalingService {
  final Map<String, SignalingChannel> _channels = {};
  void Function(SignalingChannel channel)? _inboundHandler;

  @override
  Future<SignalingChannel> connect(ConnectionCard peer) async {
    final channel = MockSignalingChannel(
      remotePubkey: peer.pubkey,
      transport: PeerTransport.lan,
    );
    _channels[peer.pubkey] = channel;
    return channel;
  }

  @override
  void onInboundConnection(
    void Function(SignalingChannel channel) handler,
  ) {
    _inboundHandler = handler;
  }

  @override
  Future<void> closeAll() async {
    for (final channel in _channels.values) {
      await channel.close();
    }
    _channels.clear();
  }

  @override
  Map<String, SignalingChannel> get activeChannels =>
      Map.unmodifiable(_channels);

  /// Simulate an inbound connection from a remote peer.
  /// Returns the channel so tests can send messages through it.
  MockSignalingChannel simulateInbound(String remotePubkey) {
    final channel = MockSignalingChannel(
      remotePubkey: remotePubkey,
      transport: PeerTransport.lan,
    );
    _channels[remotePubkey] = channel;
    _inboundHandler?.call(channel);
    return channel;
  }
}

/// In-memory signaling channel for testing.
class MockSignalingChannel implements SignalingChannel {
  MockSignalingChannel({
    required this.remotePubkey,
    required this.transport,
  });

  @override
  final String remotePubkey;

  @override
  final PeerTransport transport;

  final _controller = StreamController<Uint8List>.broadcast();
  bool _isOpen = true;

  @override
  Future<void> send(Uint8List data) async {
    if (!_isOpen) throw StateError('Channel is closed');
    // In tests, the sent data can be captured by listening to sentMessages.
    _sentMessages.add(data);
  }

  @override
  Stream<Uint8List> get messages => _controller.stream;

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> close() async {
    _isOpen = false;
    await _controller.close();
  }

  /// Messages sent via [send], for test assertions.
  final List<Uint8List> _sentMessages = [];
  List<Uint8List> get sentMessages => List.unmodifiable(_sentMessages);

  /// Simulate receiving a message from the remote peer.
  void simulateReceive(Uint8List data) {
    if (!_isOpen) throw StateError('Channel is closed');
    _controller.add(data);
  }
}
