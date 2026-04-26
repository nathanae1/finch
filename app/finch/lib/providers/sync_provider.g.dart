// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$peerConnectionFactoryHash() =>
    r'632b65b2d667f2ed5eea1c4c6b043e6288a1eabc';

/// Provides the singleton [PeerConnectionFactory] used by the sync engine
/// and `RemoteMediaFetcher`.
///
/// Copied from [peerConnectionFactory].
@ProviderFor(peerConnectionFactory)
final peerConnectionFactoryProvider =
    AutoDisposeProvider<PeerConnectionFactory>.internal(
      peerConnectionFactory,
      name: r'peerConnectionFactoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$peerConnectionFactoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PeerConnectionFactoryRef =
    AutoDisposeProviderRef<PeerConnectionFactory>;
String _$lanNetworkServiceHash() => r'43d83c8138d3a7b6fbabcb25d9644bbeed040e4f';

/// LanNetworkService singleton. The default `networkServiceProvider` is
/// the abstract interface (mock by default); the concrete LAN client is
/// kept separate so the sync engine can call `fetchEnvelope`, which is a
/// LAN-specific method not yet on the cross-tier interface.
///
/// Copied from [lanNetworkService].
@ProviderFor(lanNetworkService)
final lanNetworkServiceProvider =
    AutoDisposeProvider<LanNetworkService>.internal(
      lanNetworkService,
      name: r'lanNetworkServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$lanNetworkServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LanNetworkServiceRef = AutoDisposeProviderRef<LanNetworkService>;
String _$syncEngineHash() => r'bdad0210c6cf1a4249d92ee1495be92c506e128f';

/// See also [syncEngine].
@ProviderFor(syncEngine)
final syncEngineProvider = AutoDisposeProvider<SyncEngine>.internal(
  syncEngine,
  name: r'syncEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncEngineRef = AutoDisposeProviderRef<SyncEngine>;
String _$syncControllerHash() => r'777360950e28ada45d24ea34daad140ba4670561';

/// Surfaces sync state to the UI and exposes [syncNow] for pull-to-refresh.
///
/// Copied from [SyncController].
@ProviderFor(SyncController)
final syncControllerProvider =
    AutoDisposeNotifierProvider<SyncController, SyncEngineState>.internal(
      SyncController.new,
      name: r'syncControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncController = AutoDisposeNotifier<SyncEngineState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
