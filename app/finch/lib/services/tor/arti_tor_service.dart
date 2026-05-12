import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../tor_service.dart';
import '../types.dart';
import 'ffi_bindings.dart';

/// Real `TorService` backed by the `arti_bridge` Rust crate. Bootstrap and
/// onion-service creation block long enough that we run them on a worker
/// isolate via `Isolate.run`, keeping the Dart UI thread responsive.
class ArtiTorService implements TorService {
  ArtiTorService({ArtiBindings? bindings})
      : _bindings = bindings ?? ArtiBindings.load();

  final ArtiBindings _bindings;
  Pointer<Void>? _handle;
  String? _onionAddress;

  @override
  Future<void> init(String dataDir) async {
    if (_handle != null) return;
    final (handleAddr, errorMessage) =
        await Isolate.run<(int, String?)>(() => _initInIsolate(dataDir));
    if (handleAddr == 0) {
      final detail = errorMessage ?? 'no detail (arti_last_error empty)';
      throw TorServiceException('arti_init returned null: $detail');
    }
    _handle = Pointer<Void>.fromAddress(handleAddr);
    developer.log('Arti initialized', name: 'arti_tor_service');
  }

  @override
  Future<String> createOnionService(int localPort) async {
    final handle = _handle;
    if (handle == null) {
      throw const TorServiceException('init() must be called first');
    }
    final handleAddr = handle.address;
    final (address, errorMessage) =
        await Isolate.run<(String?, String?)>(
      () => _createOnionInIsolate(handleAddr, localPort),
    );
    if (address == null) {
      final detail = errorMessage ?? 'no detail (arti_last_error empty)';
      throw TorServiceException(
        'arti_create_onion_service returned null: $detail',
      );
    }
    _onionAddress = address;
    developer.log('onion=$address', name: 'arti_tor_service');
    return address;
  }

  @override
  Future<PeerConnection> connectToOnion(String address, int port) async {
    final handle = _handle;
    if (handle == null) {
      throw const TorServiceException('init() must be called first');
    }
    if (_bindings.socksPort(handle) == 0) {
      throw const TorServiceException(
        'Tor SOCKS5 proxy not yet bound — wait for bootstrap to complete',
      );
    }
    return PeerConnection(
      pubkey: '',
      baseUrl: 'http://$address:$port',
      transport: PeerTransport.tor,
    );
  }

  @override
  String? get onionAddress => _onionAddress;

  @override
  int get socksPort {
    final handle = _handle;
    if (handle == null) return 0;
    return _bindings.socksPort(handle);
  }

  @override
  bool get isReady {
    final handle = _handle;
    if (handle == null) return false;
    final out = malloc<ArtiStatusStruct>();
    try {
      final code = _bindings.status(handle, out);
      if (code != ArtiStatusCode.ok) return false;
      return out.ref.isReady && out.ref.socksPort != 0;
    } finally {
      malloc.free(out);
    }
  }

  @override
  TorStatus getStatus() {
    final handle = _handle;
    if (handle == null) {
      return const TorStatus(
        bootstrapPercent: 0,
        circuitCount: 0,
        isReady: false,
      );
    }
    final out = malloc<ArtiStatusStruct>();
    try {
      final code = _bindings.status(handle, out);
      if (code != ArtiStatusCode.ok) {
        return const TorStatus(
          bootstrapPercent: 0,
          circuitCount: 0,
          isReady: false,
        );
      }
      final s = out.ref;
      return TorStatus(
        bootstrapPercent: s.bootstrapPercent,
        circuitCount: s.circuitCount,
        isReady: s.isReady,
        onionAddress: _onionAddress,
      );
    } finally {
      malloc.free(out);
    }
  }

  @override
  Future<void> shutdown() async {
    final handle = _handle;
    if (handle == null) return;
    _handle = null;
    _onionAddress = null;
    final handleAddr = handle.address;
    await Isolate.run<void>(() => _shutdownInIsolate(handleAddr));
    developer.log('Arti shut down', name: 'arti_tor_service');
  }
}

// Isolate entry-points. Each rebuilds [ArtiBindings] inside the worker
// isolate so we never have to ship a non-primitive across the boundary —
// only ints and Strings cross.

(int, String?) _initInIsolate(String dataDir) {
  final bindings = ArtiBindings.load();
  final cstr = dataDir.toNativeUtf8();
  try {
    final handle = bindings.init(cstr);
    if (handle.address != 0) {
      return (handle.address, null);
    }
    final msgPtr = bindings.lastError();
    if (msgPtr == nullptr) {
      return (0, null);
    }
    try {
      return (0, msgPtr.toDartString());
    } finally {
      bindings.stringFree(msgPtr);
    }
  } finally {
    malloc.free(cstr);
  }
}

(String?, String?) _createOnionInIsolate(int handleAddr, int localPort) {
  final bindings = ArtiBindings.load();
  final ptr = bindings.createOnionService(
    Pointer<Void>.fromAddress(handleAddr),
    localPort,
  );
  if (ptr != nullptr) {
    try {
      return (ptr.toDartString(), null);
    } finally {
      bindings.stringFree(ptr);
    }
  }
  final msgPtr = bindings.lastError();
  if (msgPtr == nullptr) return (null, null);
  try {
    return (null, msgPtr.toDartString());
  } finally {
    bindings.stringFree(msgPtr);
  }
}

void _shutdownInIsolate(int handleAddr) {
  final bindings = ArtiBindings.load();
  bindings.shutdown(Pointer<Void>.fromAddress(handleAddr));
}

class TorServiceException implements Exception {
  const TorServiceException(this.message);
  final String message;
  @override
  String toString() => 'TorServiceException: $message';
}
