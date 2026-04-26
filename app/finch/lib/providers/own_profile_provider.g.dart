// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'own_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownProfileHash() => r'1886c985fa9369f3ab39c474d28cf7dfc4c21121';

/// Reads the latest kind=2 event for own pubkey and decodes its JSON content
/// into a profile snapshot. Falls back to "You" with no avatar when no
/// profile event has been written yet (the Plan 04 onboarding flow currently
/// does not write one — see the project README and Plan 04 spec for the
/// kind=2 contract; a future profile-edit screen, Plan 15, will create it).
///
/// Copied from [ownProfile].
@ProviderFor(ownProfile)
final ownProfileProvider =
    AutoDisposeFutureProvider<OwnProfileSnapshot>.internal(
      ownProfile,
      name: r'ownProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ownProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnProfileRef = AutoDisposeFutureProviderRef<OwnProfileSnapshot>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
