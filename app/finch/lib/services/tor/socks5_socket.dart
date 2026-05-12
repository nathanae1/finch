import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// A tunnel established to [targetHost]:[targetPort] through a SOCKS5
/// proxy. [socket] is writable for outbound HTTP bytes; [stream] emits
/// inbound bytes (any leftover bytes pipelined after the SOCKS reply are
/// forwarded as the first event).
///
/// We surface both halves rather than a single [Socket] because Dart's
/// `Socket` is a single-subscription [Stream], and we already had to
/// listen to it to drive the SOCKS handshake. Handing the post-handshake
/// stream out separately lets the caller (a minimal HTTP/1.1 client) read
/// the response without trying to re-listen.
class SocksTunnel {
  SocksTunnel._(this.socket, this.stream);
  final Socket socket;
  final Stream<Uint8List> stream;

  Future<void> close() async {
    await socket.close();
    socket.destroy();
  }
}

/// Opens a TCP connection to [proxyHost]:[proxyPort], performs a SOCKS5
/// no-auth CONNECT handshake to [targetHost]:[targetPort], and returns a
/// [SocksTunnel] whose [SocksTunnel.socket] is ready for application
/// writes and whose [SocksTunnel.stream] yields inbound bytes.
///
/// The target address is sent as the SOCKS5 domain-name address type
/// (`ATYP=0x03`) so the proxy resolves it. This is required for `.onion`
/// hosts: Tor must do the resolution itself, not the local DNS resolver.
///
/// Throws [SocksException] on protocol or upstream failures.
Future<SocksTunnel> openSocks5({
  required String proxyHost,
  required int proxyPort,
  required String targetHost,
  required int targetPort,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final socket = await Socket.connect(proxyHost, proxyPort, timeout: timeout);
  socket.setOption(SocketOption.tcpNoDelay, true);

  final out = StreamController<Uint8List>();
  final hs = _Handshake();

  late StreamSubscription<Uint8List> sub;
  sub = socket.listen(
    (chunk) {
      try {
        if (hs.done) {
          out.add(chunk);
          return;
        }
        final leftover = hs.feed(chunk);
        if (hs.done && leftover != null && leftover.isNotEmpty) {
          out.add(leftover);
        }
      } catch (e, st) {
        out.addError(e, st);
        sub.cancel();
        socket.destroy();
      }
    },
    onError: (Object e, StackTrace st) {
      if (!hs.done) {
        hs.failPending(e, st);
      }
      if (!out.isClosed) out.addError(e, st);
    },
    onDone: () {
      if (!hs.done) {
        hs.failPending(
          const SocksException('socket closed during SOCKS handshake'),
          StackTrace.current,
        );
      }
      if (!out.isClosed) out.close();
    },
    cancelOnError: false,
  );

  try {
    socket.add(const [0x05, 0x01, 0x00]);
    await socket.flush();
    await hs.methodReply.future.timeout(timeout);

    socket.add(_buildConnectRequest(targetHost, targetPort));
    await socket.flush();
    await hs.connectReply.future.timeout(timeout);
  } catch (e) {
    await sub.cancel();
    socket.destroy();
    if (!out.isClosed) await out.close();
    rethrow;
  }

  return SocksTunnel._(socket, out.stream);
}

Uint8List _buildConnectRequest(String host, int port) {
  final hostBytes = Uint8List.fromList(host.codeUnits);
  if (hostBytes.length > 255) {
    throw const SocksException('target host too long for SOCKS5 (max 255)');
  }
  final b = BytesBuilder()
    ..addByte(0x05) // VER
    ..addByte(0x01) // CMD = CONNECT
    ..addByte(0x00) // RSV
    ..addByte(0x03) // ATYP = domain
    ..addByte(hostBytes.length)
    ..add(hostBytes)
    ..addByte((port >> 8) & 0xff)
    ..addByte(port & 0xff);
  return b.takeBytes();
}

/// Drives the two-step SOCKS5 handshake (method selection, then CONNECT).
/// `feed(chunk)` consumes inbound bytes; once both replies are parsed,
/// `done` flips true and any extra bytes are returned to the caller for
/// forwarding to the post-handshake stream.
class _Handshake {
  final BytesBuilder _buf = BytesBuilder(copy: false);
  final Completer<void> methodReply = Completer<void>();
  final Completer<void> connectReply = Completer<void>();
  _Phase _phase = _Phase.method;

  bool get done => _phase == _Phase.done;

  Uint8List? feed(Uint8List chunk) {
    _buf.add(chunk);
    while (true) {
      switch (_phase) {
        case _Phase.method:
          if (_buf.length < 2) return null;
          final all = _buf.takeBytes();
          if (all[0] != 0x05) {
            throw SocksException('bad version in method reply: ${all[0]}');
          }
          if (all[1] != 0x00) {
            throw SocksException(
              'proxy refused no-auth (selected 0x${all[1].toRadixString(16)})',
            );
          }
          _buf.add(Uint8List.sublistView(all, 2));
          _phase = _Phase.connect;
          methodReply.complete();
          continue;
        case _Phase.connect:
          if (_buf.length < 5) return null;
          final snapshot = _buf.toBytes();
          if (snapshot[0] != 0x05) {
            throw SocksException(
              'bad version in connect reply: ${snapshot[0]}',
            );
          }
          if (snapshot[1] != 0x00) {
            throw SocksException(
              'connect failed: ${_repName(snapshot[1])} '
              '(0x${snapshot[1].toRadixString(16)})',
            );
          }
          final atyp = snapshot[3];
          int addrLen;
          switch (atyp) {
            case 0x01:
              addrLen = 4;
            case 0x03:
              addrLen = snapshot[4] + 1; // length byte + bytes
            case 0x04:
              addrLen = 16;
            default:
              throw SocksException('unsupported ATYP in reply: $atyp');
          }
          final headerLen = 4 + addrLen + 2; // VER REP RSV ATYP + addr + port
          if (snapshot.length < headerLen) return null;
          final all = _buf.takeBytes();
          final leftover = all.length > headerLen
              ? Uint8List.sublistView(all, headerLen)
              : null;
          _phase = _Phase.done;
          connectReply.complete();
          return leftover;
        case _Phase.done:
          return null;
      }
    }
  }

  void failPending(Object e, StackTrace st) {
    if (!methodReply.isCompleted) methodReply.completeError(e, st);
    if (!connectReply.isCompleted) connectReply.completeError(e, st);
  }
}

enum _Phase { method, connect, done }

String _repName(int code) {
  switch (code) {
    case 0x01:
      return 'general failure';
    case 0x02:
      return 'connection not allowed';
    case 0x03:
      return 'network unreachable';
    case 0x04:
      return 'host unreachable';
    case 0x05:
      return 'connection refused';
    case 0x06:
      return 'TTL expired';
    case 0x07:
      return 'command not supported';
    case 0x08:
      return 'address type not supported';
    default:
      return 'unknown';
  }
}

class SocksException implements Exception {
  const SocksException(this.message);
  final String message;
  @override
  String toString() => 'SocksException: $message';
}
