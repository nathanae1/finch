// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$composeControllerHash() => r'0121d0c04bce104939271e86e27a4eb79d358c1c';

/// Compose-screen scratch state. Lives across Compose → Preview → back-to-edit
/// so the photo and caption survive the sub-route push. Invalidate on modal
/// close (either ✕ or successful publish).
///
/// `keepAlive: true` so the state survives the transient gap between the ✕
/// icon popping Compose and any listener re-subscribing — and so that tests
/// that seed state via [ComposeController.debugSeedState] before the
/// widget tree mounts don't lose it to auto-dispose.
///
/// Copied from [ComposeController].
@ProviderFor(ComposeController)
final composeControllerProvider =
    NotifierProvider<ComposeController, ComposeState>.internal(
      ComposeController.new,
      name: r'composeControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$composeControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ComposeController = Notifier<ComposeState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
