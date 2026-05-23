// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single-instance LastViewedTracker for the running app. Lives at the
/// provider scope so the dedupe set survives across feed rebuilds but
/// dies with the app process.

@ProviderFor(lastViewedTracker)
final lastViewedTrackerProvider = LastViewedTrackerProvider._();

/// Single-instance LastViewedTracker for the running app. Lives at the
/// provider scope so the dedupe set survives across feed rebuilds but
/// dies with the app process.

final class LastViewedTrackerProvider
    extends
        $FunctionalProvider<
          LastViewedTracker,
          LastViewedTracker,
          LastViewedTracker
        >
    with $Provider<LastViewedTracker> {
  /// Single-instance LastViewedTracker for the running app. Lives at the
  /// provider scope so the dedupe set survives across feed rebuilds but
  /// dies with the app process.
  LastViewedTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastViewedTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastViewedTrackerHash();

  @$internal
  @override
  $ProviderElement<LastViewedTracker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LastViewedTracker create(Ref ref) {
    return lastViewedTracker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastViewedTracker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastViewedTracker>(value),
    );
  }
}

String _$lastViewedTrackerHash() => r'96e1cb52d02aab043d964b7b9131a8bdafaf6b87';

/// Reverse-chronological feed of kind=1 posts from own identity + active
/// follows. Posts with a kind=6 tombstone from the same author are excluded
/// at the storage layer. Plan 09 plugs sync into this — the provider shape
/// doesn't change.

@ProviderFor(feed)
final feedProvider = FeedProvider._();

/// Reverse-chronological feed of kind=1 posts from own identity + active
/// follows. Posts with a kind=6 tombstone from the same author are excluded
/// at the storage layer. Plan 09 plugs sync into this — the provider shape
/// doesn't change.

final class FeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Reverse-chronological feed of kind=1 posts from own identity + active
  /// follows. Posts with a kind=6 tombstone from the same author are excluded
  /// at the storage layer. Plan 09 plugs sync into this — the provider shape
  /// doesn't change.
  FeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedHash();

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    return feed(ref);
  }
}

String _$feedHash() => r'7b48a5dbe60b144ea3bf37dbea65d161355a8186';

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.

@ProviderFor(eventById)
final eventByIdProvider = EventByIdFamily._();

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.

final class EventByIdProvider
    extends $FunctionalProvider<AsyncValue<Event?>, Event?, FutureOr<Event?>>
    with $FutureModifier<Event?>, $FutureProvider<Event?> {
  /// Single event by id, used by the post-detail screen so it doesn't have
  /// to re-query the whole feed.
  EventByIdProvider._({
    required EventByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventByIdHash();

  @override
  String toString() {
    return r'eventByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Event?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Event?> create(Ref ref) {
    final argument = this.argument as String;
    return eventById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventByIdHash() => r'1c419a1fe059310f471dc7ebe37dee164123713c';

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.

final class EventByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Event?>, String> {
  EventByIdFamily._()
    : super(
        retry: null,
        name: r'eventByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single event by id, used by the post-detail screen so it doesn't have
  /// to re-query the whole feed.

  EventByIdProvider call(String id) =>
      EventByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'eventByIdProvider';
}

/// Own posts (kind=1, deletes excluded) for the "You"-tab grid.

@ProviderFor(ownPosts)
final ownPostsProvider = OwnPostsProvider._();

/// Own posts (kind=1, deletes excluded) for the "You"-tab grid.

final class OwnPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Own posts (kind=1, deletes excluded) for the "You"-tab grid.
  OwnPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownPostsHash();

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    return ownPosts(ref);
  }
}

String _$ownPostsHash() => r'2f4352c8fdc7bc624452fca2403100d0e82e85ee';

/// Posts authored by a given pubkey, for other-profile grid.

@ProviderFor(profilePosts)
final profilePostsProvider = ProfilePostsFamily._();

/// Posts authored by a given pubkey, for other-profile grid.

final class ProfilePostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Posts authored by a given pubkey, for other-profile grid.
  ProfilePostsProvider._({
    required ProfilePostsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profilePostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profilePostsHash();

  @override
  String toString() {
    return r'profilePostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    final argument = this.argument as String;
    return profilePosts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfilePostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profilePostsHash() => r'57f87e6321e83224bd2535b309c5703fe7c9cbf9';

/// Posts authored by a given pubkey, for other-profile grid.

final class ProfilePostsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Event>>, String> {
  ProfilePostsFamily._()
    : super(
        retry: null,
        name: r'profilePostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Posts authored by a given pubkey, for other-profile grid.

  ProfilePostsProvider call(String pubkey) =>
      ProfilePostsProvider._(argument: pubkey, from: this);

  @override
  String toString() => r'profilePostsProvider';
}
