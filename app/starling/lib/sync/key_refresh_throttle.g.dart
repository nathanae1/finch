// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_refresh_throttle.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton. Shared by EncryptedImage and the connection
/// settings refresh so a tile-level button-mash doesn't bypass the
/// widget-level cooldown (or vice versa).

@ProviderFor(keyRefreshThrottle)
final keyRefreshThrottleProvider = KeyRefreshThrottleProvider._();

/// App-wide singleton. Shared by EncryptedImage and the connection
/// settings refresh so a tile-level button-mash doesn't bypass the
/// widget-level cooldown (or vice versa).

final class KeyRefreshThrottleProvider
    extends
        $FunctionalProvider<
          KeyRefreshThrottle,
          KeyRefreshThrottle,
          KeyRefreshThrottle
        >
    with $Provider<KeyRefreshThrottle> {
  /// App-wide singleton. Shared by EncryptedImage and the connection
  /// settings refresh so a tile-level button-mash doesn't bypass the
  /// widget-level cooldown (or vice versa).
  KeyRefreshThrottleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keyRefreshThrottleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keyRefreshThrottleHash();

  @$internal
  @override
  $ProviderElement<KeyRefreshThrottle> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KeyRefreshThrottle create(Ref ref) {
    return keyRefreshThrottle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyRefreshThrottle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyRefreshThrottle>(value),
    );
  }
}

String _$keyRefreshThrottleHash() =>
    r'd957c8157fb8f550d7d12a28cc856e401891a920';
