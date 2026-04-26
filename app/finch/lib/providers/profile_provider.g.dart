// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingProfileControllerHash() =>
    r'dd10aa7a1abfdd44f241b9b0fd08661e93f0b528';

/// Transient onboarding profile state — name + avatar the user is entering on
/// the Setup screen before anything is persisted. Cleared once onboarding
/// completes. The durable profile (loaded from the latest kind=2 event) will
/// live on a separate provider once Plan 05 lands.
///
/// Copied from [OnboardingProfileController].
@ProviderFor(OnboardingProfileController)
final onboardingProfileControllerProvider =
    AutoDisposeNotifierProvider<OnboardingProfileController, Profile>.internal(
      OnboardingProfileController.new,
      name: r'onboardingProfileControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onboardingProfileControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnboardingProfileController = AutoDisposeNotifier<Profile>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
