// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownEndpointsHash() => r'5f4bc1752906e9332cfe119bbbfab829c6d30dca';

/// Endpoints we currently advertise to peers. Plan 08 shipped only a
/// `direct: 127.0.0.1:<port>` entry, which lets two simulators on one Mac
/// complete the handshake but doesn't work between physical devices on
/// the same WiFi. Plan 09 adds `lan-direct: <LAN_IP>:<port>` so a QR-scan
/// handshake works across two real phones. Plan 11 will add the Tor
/// onion address.
///
/// Copied from [ownEndpoints].
@ProviderFor(ownEndpoints)
final ownEndpointsProvider = AutoDisposeFutureProvider<List<Endpoint>>.internal(
  ownEndpoints,
  name: r'ownEndpointsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownEndpointsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnEndpointsRef = AutoDisposeFutureProviderRef<List<Endpoint>>;
String _$followServiceHash() => r'5d78eb7cc862574f6933cbed50a3e0c27bfb31d1';

/// Singleton [FollowService] for the running app. Constructs the real
/// HTTP transport, wires identity / secret-key lookups, and points the
/// service at the live storage + crypto.
///
/// Copied from [followService].
@ProviderFor(followService)
final followServiceProvider = AutoDisposeProvider<FollowService>.internal(
  followService,
  name: r'followServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowServiceRef = AutoDisposeProviderRef<FollowService>;
String _$ownConnectionCardHash() => r'94af7bdf15f58111979f7215272636e6ff466a3d';

/// Convenience: assemble the connection card we share via QR.
///
/// Copied from [ownConnectionCard].
@ProviderFor(ownConnectionCard)
final ownConnectionCardProvider =
    AutoDisposeFutureProvider<ConnectionCard?>.internal(
      ownConnectionCard,
      name: r'ownConnectionCardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ownConnectionCardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnConnectionCardRef = AutoDisposeFutureProviderRef<ConnectionCard?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
