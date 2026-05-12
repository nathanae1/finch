// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follows_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All active follows. Plan 08 wires the real management UI; Plan 06 just
/// needs the list (count + per-pubkey lookups for profile rendering).

@ProviderFor(follows)
final followsProvider = FollowsProvider._();

/// All active follows. Plan 08 wires the real management UI; Plan 06 just
/// needs the list (count + per-pubkey lookups for profile rendering).

final class FollowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Follow>>,
          List<Follow>,
          FutureOr<List<Follow>>
        >
    with $FutureModifier<List<Follow>>, $FutureProvider<List<Follow>> {
  /// All active follows. Plan 08 wires the real management UI; Plan 06 just
  /// needs the list (count + per-pubkey lookups for profile rendering).
  FollowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsHash();

  @$internal
  @override
  $FutureProviderElement<List<Follow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Follow>> create(Ref ref) {
    return follows(ref);
  }
}

String _$followsHash() => r'29a8a3232de480be5e45eac1c72eefec4e5711eb';

/// Live stream of active follows. Friends-tab UI watches this so accept /
/// unfollow operations re-render without manual invalidation.

@ProviderFor(followsStream)
final followsStreamProvider = FollowsStreamProvider._();

/// Live stream of active follows. Friends-tab UI watches this so accept /
/// unfollow operations re-render without manual invalidation.

final class FollowsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Follow>>,
          List<Follow>,
          Stream<List<Follow>>
        >
    with $FutureModifier<List<Follow>>, $StreamProvider<List<Follow>> {
  /// Live stream of active follows. Friends-tab UI watches this so accept /
  /// unfollow operations re-render without manual invalidation.
  FollowsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Follow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Follow>> create(Ref ref) {
    return followsStream(ref);
  }
}

String _$followsStreamHash() => r'f26e881a80ab2e35996306e2f83d71b8dad768bf';
