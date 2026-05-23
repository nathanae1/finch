// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the mDNS lifecycle. Once both the identity is loaded and the HTTP
/// server has bound a port, registers the `_starling._tcp` service and
/// streams the live peer cache. Disposes by deregistering.
///
/// The published value is the current peer map (keyed by peer pubkey).
/// Pull-to-refresh in the feed can call [DiscoveryController.rescan] to
/// trigger a fresh browse round.

@ProviderFor(DiscoveryController)
final discoveryControllerProvider = DiscoveryControllerProvider._();

/// Owns the mDNS lifecycle. Once both the identity is loaded and the HTTP
/// server has bound a port, registers the `_starling._tcp` service and
/// streams the live peer cache. Disposes by deregistering.
///
/// The published value is the current peer map (keyed by peer pubkey).
/// Pull-to-refresh in the feed can call [DiscoveryController.rescan] to
/// trigger a fresh browse round.
final class DiscoveryControllerProvider
    extends $AsyncNotifierProvider<DiscoveryController, Map<String, LanPeer>> {
  /// Owns the mDNS lifecycle. Once both the identity is loaded and the HTTP
  /// server has bound a port, registers the `_starling._tcp` service and
  /// streams the live peer cache. Disposes by deregistering.
  ///
  /// The published value is the current peer map (keyed by peer pubkey).
  /// Pull-to-refresh in the feed can call [DiscoveryController.rescan] to
  /// trigger a fresh browse round.
  DiscoveryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryControllerHash();

  @$internal
  @override
  DiscoveryController create() => DiscoveryController();
}

String _$discoveryControllerHash() =>
    r'35c7a50e363970b4ed6d8a59614c2533e8fc3a03';

/// Owns the mDNS lifecycle. Once both the identity is loaded and the HTTP
/// server has bound a port, registers the `_starling._tcp` service and
/// streams the live peer cache. Disposes by deregistering.
///
/// The published value is the current peer map (keyed by peer pubkey).
/// Pull-to-refresh in the feed can call [DiscoveryController.rescan] to
/// trigger a fresh browse round.

abstract class _$DiscoveryController
    extends $AsyncNotifier<Map<String, LanPeer>> {
  FutureOr<Map<String, LanPeer>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, LanPeer>>, Map<String, LanPeer>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, LanPeer>>,
                Map<String, LanPeer>
              >,
              AsyncValue<Map<String, LanPeer>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
