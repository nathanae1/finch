// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$discoveryControllerHash() =>
    r'21e398e339a87c5dfa4639d924dfa1ff1862f3ad';

/// Owns the mDNS lifecycle. Once both the identity is loaded and the HTTP
/// server has bound a port, registers the `_finch._tcp` service and
/// streams the live peer cache. Disposes by deregistering.
///
/// The published value is the current peer map (keyed by peer pubkey).
/// Pull-to-refresh in the feed can call [DiscoveryController.rescan] to
/// trigger a fresh browse round.
///
/// Copied from [DiscoveryController].
@ProviderFor(DiscoveryController)
final discoveryControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      DiscoveryController,
      Map<String, LanPeer>
    >.internal(
      DiscoveryController.new,
      name: r'discoveryControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$discoveryControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DiscoveryController = AutoDisposeAsyncNotifier<Map<String, LanPeer>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
