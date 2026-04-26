// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_paths_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSupportDirectoryHash() =>
    r'3984c3a19ab48e137c73b94c123e83333f97229f';

/// The platform's application-support directory. Finch writes media blobs,
/// indexes, and other non-user-visible state here — not into the user's
/// Documents dir (which is surfaced in the iOS Files app / iTunes file
/// sharing).
///
/// Tests override this with a tmp dir.
///
/// Copied from [appSupportDirectory].
@ProviderFor(appSupportDirectory)
final appSupportDirectoryProvider =
    AutoDisposeFutureProvider<Directory>.internal(
      appSupportDirectory,
      name: r'appSupportDirectoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appSupportDirectoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppSupportDirectoryRef = AutoDisposeFutureProviderRef<Directory>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
