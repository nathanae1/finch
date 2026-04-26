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
///
/// Plan 11a scope: bootstrap, publish onion, expose status, shutdown.
/// `connectToOnion` is not wired here — Plan 11b will route an `http.Client`
/// through Arti's SOCKS5 proxy. Until then it throws.
class ArtiTorService implements TorService {
  ArtiTorService({ArtiBindings? bindings})
      : _bindings = bindings ?? ArtiBindings.load();

  final ArtiBindings _bindings;
  Pointer<Void>? _handle;

  @override
  Future<void> init(String dataDir) async {
    if (_handle != null) return;
    final ptrAddress = await Isolate.run<int>(() => _initInIsolate(dataDir));
    if (ptrAddress == 0) {
      throw const TorServiceException('arti_init returned null');
    }
    _handle = Pointer<Void>.fromAddress(ptrAddress);
    developer.log('Arti initialized', name: 'arti_tor_service');
  }

  @override
  Future<String> createOnionService(int localPort) async {
    final handle = _handle;
    if (handle == null) {
      throw const TorServiceException('init() must be called first');
    }
    final handleAddr = handle.address;
    final address = await Isolate.run<String?>(
      () => _createOnionInIsolate(handleAddr, localPort),
    );
    if (address == null) {
      throw const TorServiceException(
          'arti_create_onion_service returned null');
    }
    developer.log('onion=$address', name: 'arti_tor_service');
    return address;
  }

  @override
  Future<PeerConnection> connectToOnion(String address, int port) async {
    // Plan 11b: route through Arti's SOCKS5 proxy. For 11a we don't dial
    // outbound onions yet; sync stays LAN-only.
    throw const TorServiceException(
      'ArtiTorService.connectToOnion arrives in Plan 11b',
    );
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
        // We don't expose the .onion address through getStatus in 11a —
        // main.dart caches whatever createOnionService returned. Plan 11b
        // can read it back from Rust if needed.
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
    final handleAddr = handle.address;
    await Isolate.run<void>(() => _shutdownInIsolate(handleAddr));
    developer.log('Arti shut down', name: 'arti_tor_service');
  }
}

// Isolate entry-points. Each rebuilds [ArtiBindings] inside the worker
// isolate so we never have to ship a non-primitive across the boundary —
// only ints and Strings cross.

int _initInIsolate(String dataDir) {
  final bindings = ArtiBindings.load();
  final cstr = dataDir.toNativeUtf8();
  try {
    return bindings.init(cstr).address;
  } finally {
    malloc.free(cstr);
  }
}

String? _createOnionInIsolate(int handleAddr, int localPort) {
  final bindings = ArtiBindings.load();
  final ptr = bindings.createOnionService(
    Pointer<Void>.fromAddress(handleAddr),
    localPort,
  );
  if (ptr == nullptr) return null;
  try {
    return ptr.toDartString();
  } finally {
    bindings.stringFree(ptr);
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
