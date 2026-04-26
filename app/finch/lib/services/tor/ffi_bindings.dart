import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Hand-written bindings to `native/arti_bridge/include/arti_bridge.h`.
/// Layouts here MUST match the `#[repr(C)]` types in `arti_bridge/src/lib.rs`.
///
/// On Android the shared library `libarti_bridge.so` is loaded by name from
/// the per-arch `jniLibs/` directory; on iOS the static `arti_bridge.xcframework`
/// is linked into the app binary, so we resolve symbols from `process()`.

/// Status codes mirrored from the Rust C-API.
class ArtiStatusCode {
  static const int ok = 0;
  static const int errNull = -1;
  static const int errUtf8 = -2;
  static const int errPanic = -3;
  static const int errInit = -4;
  static const int errOnion = -5;
  static const int errShutdown = -6;
}

/// Mirror of `ArtiStatus` in `lib.rs`. Layout-sensitive: 4-byte aligned with
/// a packed bool, then a u16. The C compiler will pad after `is_ready`, so
/// we pad explicitly.
final class ArtiStatusStruct extends Struct {
  @Uint32()
  external int bootstrapPercent;

  @Uint32()
  external int circuitCount;

  @Bool()
  external bool isReady;

  // dart:ffi inserts the 1-byte alignment pad between [isReady] and
  // [socksPort] automatically — matches Rust's `#[repr(C)]` layout.
  @Uint16()
  external int socksPort;
}

typedef ArtiInitNative = Pointer<Void> Function(Pointer<Utf8>);
typedef ArtiInitDart = Pointer<Void> Function(Pointer<Utf8>);

typedef ArtiCreateOnionServiceNative = Pointer<Utf8> Function(
    Pointer<Void>, Uint16);
typedef ArtiCreateOnionServiceDart = Pointer<Utf8> Function(
    Pointer<Void>, int);

typedef ArtiSocksPortNative = Uint16 Function(Pointer<Void>);
typedef ArtiSocksPortDart = int Function(Pointer<Void>);

typedef ArtiStatusNative = Int32 Function(
    Pointer<Void>, Pointer<ArtiStatusStruct>);
typedef ArtiStatusDart = int Function(
    Pointer<Void>, Pointer<ArtiStatusStruct>);

typedef ArtiShutdownNative = Int32 Function(Pointer<Void>);
typedef ArtiShutdownDart = int Function(Pointer<Void>);

typedef ArtiStringFreeNative = Void Function(Pointer<Utf8>);
typedef ArtiStringFreeDart = void Function(Pointer<Utf8>);

class ArtiBindings {
  ArtiBindings._(DynamicLibrary lib)
      : init = lib
            .lookupFunction<ArtiInitNative, ArtiInitDart>('arti_init'),
        createOnionService = lib.lookupFunction<ArtiCreateOnionServiceNative,
            ArtiCreateOnionServiceDart>('arti_create_onion_service'),
        socksPort = lib.lookupFunction<ArtiSocksPortNative, ArtiSocksPortDart>(
            'arti_socks_port'),
        status = lib.lookupFunction<ArtiStatusNative, ArtiStatusDart>(
            'arti_status'),
        shutdown = lib.lookupFunction<ArtiShutdownNative, ArtiShutdownDart>(
            'arti_shutdown'),
        stringFree =
            lib.lookupFunction<ArtiStringFreeNative, ArtiStringFreeDart>(
                'arti_string_free');

  final ArtiInitDart init;
  final ArtiCreateOnionServiceDart createOnionService;
  final ArtiSocksPortDart socksPort;
  final ArtiStatusDart status;
  final ArtiShutdownDart shutdown;
  final ArtiStringFreeDart stringFree;

  static ArtiBindings? _instance;

  /// Resolves the platform's Arti library and caches the bindings.
  factory ArtiBindings.load() {
    final cached = _instance;
    if (cached != null) return cached;
    final lib = _openLibrary();
    final bindings = ArtiBindings._(lib);
    _instance = bindings;
    return bindings;
  }

  static DynamicLibrary _openLibrary() {
    if (Platform.isIOS || Platform.isMacOS) {
      // Statically linked into the app via xcframework.
      return DynamicLibrary.process();
    }
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libarti_bridge.so');
    }
    // Linux/Windows desktop builds aren't part of Plan 11; let tests that
    // import this fail loudly rather than silently load the wrong thing.
    throw UnsupportedError(
      'arti_bridge is only built for iOS and Android in Plan 11',
    );
  }
}
