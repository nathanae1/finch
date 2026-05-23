// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer_reachability_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton [PeerReachabilityMonitor]. Kept alive across the app
/// lifecycle so probe state survives screen transitions. `start()` must
/// be invoked once at launch — `main.dart`'s `_StarlingAppState.initState`
/// does that.

@ProviderFor(peerReachabilityMonitor)
final peerReachabilityMonitorProvider = PeerReachabilityMonitorProvider._();

/// Singleton [PeerReachabilityMonitor]. Kept alive across the app
/// lifecycle so probe state survives screen transitions. `start()` must
/// be invoked once at launch — `main.dart`'s `_StarlingAppState.initState`
/// does that.

final class PeerReachabilityMonitorProvider
    extends
        $FunctionalProvider<
          PeerReachabilityMonitor,
          PeerReachabilityMonitor,
          PeerReachabilityMonitor
        >
    with $Provider<PeerReachabilityMonitor> {
  /// Singleton [PeerReachabilityMonitor]. Kept alive across the app
  /// lifecycle so probe state survives screen transitions. `start()` must
  /// be invoked once at launch — `main.dart`'s `_StarlingAppState.initState`
  /// does that.
  PeerReachabilityMonitorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'peerReachabilityMonitorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$peerReachabilityMonitorHash();

  @$internal
  @override
  $ProviderElement<PeerReachabilityMonitor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PeerReachabilityMonitor create(Ref ref) {
    return peerReachabilityMonitor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PeerReachabilityMonitor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PeerReachabilityMonitor>(value),
    );
  }
}

String _$peerReachabilityMonitorHash() =>
    r'6198b22e3abd151c263d842273bbf2ef880b04a8';

/// Live reachability state keyed by pubkey. Seeded with the monitor's
/// current snapshot so first build doesn't flash empty before the stream
/// emits.

@ProviderFor(peerReachabilityState)
final peerReachabilityStateProvider = PeerReachabilityStateProvider._();

/// Live reachability state keyed by pubkey. Seeded with the monitor's
/// current snapshot so first build doesn't flash empty before the stream
/// emits.

final class PeerReachabilityStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, PeerReachability>>,
          Map<String, PeerReachability>,
          Stream<Map<String, PeerReachability>>
        >
    with
        $FutureModifier<Map<String, PeerReachability>>,
        $StreamProvider<Map<String, PeerReachability>> {
  /// Live reachability state keyed by pubkey. Seeded with the monitor's
  /// current snapshot so first build doesn't flash empty before the stream
  /// emits.
  PeerReachabilityStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'peerReachabilityStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$peerReachabilityStateHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, PeerReachability>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, PeerReachability>> create(Ref ref) {
    return peerReachabilityState(ref);
  }
}

String _$peerReachabilityStateHash() =>
    r'814955141b3a843e946153e9c71169c4aa0d0a43';
