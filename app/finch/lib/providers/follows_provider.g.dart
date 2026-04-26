// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follows_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followsHash() => r'5d068c870ff0194fd7b5fed6179bf13d75b49d08';

/// All active follows. Plan 08 wires the real management UI; Plan 06 just
/// needs the list (count + per-pubkey lookups for profile rendering).
///
/// Copied from [follows].
@ProviderFor(follows)
final followsProvider = AutoDisposeFutureProvider<List<Follow>>.internal(
  follows,
  name: r'followsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowsRef = AutoDisposeFutureProviderRef<List<Follow>>;
String _$followsStreamHash() => r'a2547df71c9ae44e46a5c5b31703a75e2f5bfa41';

/// Live stream of active follows. Friends-tab UI watches this so accept /
/// unfollow operations re-render without manual invalidation.
///
/// Copied from [followsStream].
@ProviderFor(followsStream)
final followsStreamProvider = AutoDisposeStreamProvider<List<Follow>>.internal(
  followsStream,
  name: r'followsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowsStreamRef = AutoDisposeStreamProviderRef<List<Follow>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
