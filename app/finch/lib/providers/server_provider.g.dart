// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$httpServerControllerHash() =>
    r'c06a5f2a708671c6a995d615938978fc90a1fa0e';

/// Lifecycle owner for the embedded [FinchHttpServer]. The published
/// state is the bound port (or `null` while pre-onboarding / stopped),
/// so consumers like Plan 09 (mDNS) and Plan 11 (Tor) can `ref.watch` it.
///
/// Copied from [HttpServerController].
@ProviderFor(HttpServerController)
final httpServerControllerProvider =
    AutoDisposeAsyncNotifierProvider<HttpServerController, int?>.internal(
      HttpServerController.new,
      name: r'httpServerControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$httpServerControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HttpServerController = AutoDisposeAsyncNotifier<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
