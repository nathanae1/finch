// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$identityControllerHash() =>
    r'61df561037e1493e1fb81d2f6992e6b901c8a384';

/// Loads the local identity row from storage. `null` means onboarding is not
/// complete yet. Router uses this to redirect to the welcome screen.
///
/// Copied from [IdentityController].
@ProviderFor(IdentityController)
final identityControllerProvider =
    AutoDisposeAsyncNotifierProvider<IdentityController, Identity?>.internal(
      IdentityController.new,
      name: r'identityControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$identityControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IdentityController = AutoDisposeAsyncNotifier<Identity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
