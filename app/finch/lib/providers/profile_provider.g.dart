// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Transient onboarding profile state — name + avatar the user is entering on
/// the Setup screen before anything is persisted. Cleared once onboarding
/// completes. The durable profile (loaded from the latest kind=2 event) will
/// live on a separate provider once Plan 05 lands.

@ProviderFor(OnboardingProfileController)
final onboardingProfileControllerProvider =
    OnboardingProfileControllerProvider._();

/// Transient onboarding profile state — name + avatar the user is entering on
/// the Setup screen before anything is persisted. Cleared once onboarding
/// completes. The durable profile (loaded from the latest kind=2 event) will
/// live on a separate provider once Plan 05 lands.
final class OnboardingProfileControllerProvider
    extends $NotifierProvider<OnboardingProfileController, Profile> {
  /// Transient onboarding profile state — name + avatar the user is entering on
  /// the Setup screen before anything is persisted. Cleared once onboarding
  /// completes. The durable profile (loaded from the latest kind=2 event) will
  /// live on a separate provider once Plan 05 lands.
  OnboardingProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProfileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingProfileControllerHash();

  @$internal
  @override
  OnboardingProfileController create() => OnboardingProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Profile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Profile>(value),
    );
  }
}

String _$onboardingProfileControllerHash() =>
    r'dd10aa7a1abfdd44f241b9b0fd08661e93f0b528';

/// Transient onboarding profile state — name + avatar the user is entering on
/// the Setup screen before anything is persisted. Cleared once onboarding
/// completes. The durable profile (loaded from the latest kind=2 event) will
/// live on a separate provider once Plan 05 lands.

abstract class _$OnboardingProfileController extends $Notifier<Profile> {
  Profile build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Profile, Profile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Profile, Profile>,
              Profile,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
