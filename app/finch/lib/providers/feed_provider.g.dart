// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedHash() => r'772c4ca05ae3ea7bca6bd55aa605c323689e7bb3';

/// Reverse-chronological feed of kind=1 posts from own identity + active
/// follows. Posts with a kind=6 tombstone from the same author are excluded
/// at the storage layer. Plan 09 plugs sync into this — the provider shape
/// doesn't change.
///
/// Copied from [feed].
@ProviderFor(feed)
final feedProvider = AutoDisposeFutureProvider<List<Event>>.internal(
  feed,
  name: r'feedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRef = AutoDisposeFutureProviderRef<List<Event>>;
String _$eventByIdHash() => r'42e583f34e64c93a50c539c577f10eb14c3d555b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.
///
/// Copied from [eventById].
@ProviderFor(eventById)
const eventByIdProvider = EventByIdFamily();

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.
///
/// Copied from [eventById].
class EventByIdFamily extends Family<AsyncValue<Event?>> {
  /// Single event by id, used by the post-detail screen so it doesn't have
  /// to re-query the whole feed.
  ///
  /// Copied from [eventById].
  const EventByIdFamily();

  /// Single event by id, used by the post-detail screen so it doesn't have
  /// to re-query the whole feed.
  ///
  /// Copied from [eventById].
  EventByIdProvider call(String id) {
    return EventByIdProvider(id);
  }

  @override
  EventByIdProvider getProviderOverride(covariant EventByIdProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'eventByIdProvider';
}

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.
///
/// Copied from [eventById].
class EventByIdProvider extends AutoDisposeFutureProvider<Event?> {
  /// Single event by id, used by the post-detail screen so it doesn't have
  /// to re-query the whole feed.
  ///
  /// Copied from [eventById].
  EventByIdProvider(String id)
    : this._internal(
        (ref) => eventById(ref as EventByIdRef, id),
        from: eventByIdProvider,
        name: r'eventByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$eventByIdHash,
        dependencies: EventByIdFamily._dependencies,
        allTransitiveDependencies: EventByIdFamily._allTransitiveDependencies,
        id: id,
      );

  EventByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Event?> Function(EventByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EventByIdProvider._internal(
        (ref) => create(ref as EventByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Event?> createElement() {
    return _EventByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EventByIdRef on AutoDisposeFutureProviderRef<Event?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _EventByIdProviderElement extends AutoDisposeFutureProviderElement<Event?>
    with EventByIdRef {
  _EventByIdProviderElement(super.provider);

  @override
  String get id => (origin as EventByIdProvider).id;
}

String _$ownPostsHash() => r'ba195c5526984f8ad0166a58da6196465ec861b7';

/// Own posts (kind=1, deletes excluded) for the "You"-tab grid.
///
/// Copied from [ownPosts].
@ProviderFor(ownPosts)
final ownPostsProvider = AutoDisposeFutureProvider<List<Event>>.internal(
  ownPosts,
  name: r'ownPostsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownPostsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnPostsRef = AutoDisposeFutureProviderRef<List<Event>>;
String _$profilePostsHash() => r'7351f14ed5a79283df6c7f6d07f7ac5b2f4a5da0';

/// Posts authored by a given pubkey, for other-profile grid.
///
/// Copied from [profilePosts].
@ProviderFor(profilePosts)
const profilePostsProvider = ProfilePostsFamily();

/// Posts authored by a given pubkey, for other-profile grid.
///
/// Copied from [profilePosts].
class ProfilePostsFamily extends Family<AsyncValue<List<Event>>> {
  /// Posts authored by a given pubkey, for other-profile grid.
  ///
  /// Copied from [profilePosts].
  const ProfilePostsFamily();

  /// Posts authored by a given pubkey, for other-profile grid.
  ///
  /// Copied from [profilePosts].
  ProfilePostsProvider call(String pubkey) {
    return ProfilePostsProvider(pubkey);
  }

  @override
  ProfilePostsProvider getProviderOverride(
    covariant ProfilePostsProvider provider,
  ) {
    return call(provider.pubkey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profilePostsProvider';
}

/// Posts authored by a given pubkey, for other-profile grid.
///
/// Copied from [profilePosts].
class ProfilePostsProvider extends AutoDisposeFutureProvider<List<Event>> {
  /// Posts authored by a given pubkey, for other-profile grid.
  ///
  /// Copied from [profilePosts].
  ProfilePostsProvider(String pubkey)
    : this._internal(
        (ref) => profilePosts(ref as ProfilePostsRef, pubkey),
        from: profilePostsProvider,
        name: r'profilePostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$profilePostsHash,
        dependencies: ProfilePostsFamily._dependencies,
        allTransitiveDependencies:
            ProfilePostsFamily._allTransitiveDependencies,
        pubkey: pubkey,
      );

  ProfilePostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pubkey,
  }) : super.internal();

  final String pubkey;

  @override
  Override overrideWith(
    FutureOr<List<Event>> Function(ProfilePostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProfilePostsProvider._internal(
        (ref) => create(ref as ProfilePostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pubkey: pubkey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Event>> createElement() {
    return _ProfilePostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfilePostsProvider && other.pubkey == pubkey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pubkey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfilePostsRef on AutoDisposeFutureProviderRef<List<Event>> {
  /// The parameter `pubkey` of this provider.
  String get pubkey;
}

class _ProfilePostsProviderElement
    extends AutoDisposeFutureProviderElement<List<Event>>
    with ProfilePostsRef {
  _ProfilePostsProviderElement(super.provider);

  @override
  String get pubkey => (origin as ProfilePostsProvider).pubkey;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
