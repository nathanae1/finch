// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventSavedHash() => r'79e728b45cf31ecbfa21a6dd9574e287d343c7e4';

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

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.
///
/// Copied from [eventSaved].
@ProviderFor(eventSaved)
const eventSavedProvider = EventSavedFamily();

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.
///
/// Copied from [eventSaved].
class EventSavedFamily extends Family<AsyncValue<bool>> {
  /// Whether the local viewer has bookmarked (saved) the post with [id].
  /// Local-only — never produces a synced event. See Plan 10's Save discussion.
  ///
  /// Copied from [eventSaved].
  const EventSavedFamily();

  /// Whether the local viewer has bookmarked (saved) the post with [id].
  /// Local-only — never produces a synced event. See Plan 10's Save discussion.
  ///
  /// Copied from [eventSaved].
  EventSavedProvider call(String id) {
    return EventSavedProvider(id);
  }

  @override
  EventSavedProvider getProviderOverride(
    covariant EventSavedProvider provider,
  ) {
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
  String? get name => r'eventSavedProvider';
}

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.
///
/// Copied from [eventSaved].
class EventSavedProvider extends AutoDisposeFutureProvider<bool> {
  /// Whether the local viewer has bookmarked (saved) the post with [id].
  /// Local-only — never produces a synced event. See Plan 10's Save discussion.
  ///
  /// Copied from [eventSaved].
  EventSavedProvider(String id)
    : this._internal(
        (ref) => eventSaved(ref as EventSavedRef, id),
        from: eventSavedProvider,
        name: r'eventSavedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$eventSavedHash,
        dependencies: EventSavedFamily._dependencies,
        allTransitiveDependencies: EventSavedFamily._allTransitiveDependencies,
        id: id,
      );

  EventSavedProvider._internal(
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
    FutureOr<bool> Function(EventSavedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EventSavedProvider._internal(
        (ref) => create(ref as EventSavedRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _EventSavedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventSavedProvider && other.id == id;
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
mixin EventSavedRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `id` of this provider.
  String get id;
}

class _EventSavedProviderElement extends AutoDisposeFutureProviderElement<bool>
    with EventSavedRef {
  _EventSavedProviderElement(super.provider);

  @override
  String get id => (origin as EventSavedProvider).id;
}

String _$bookmarkControllerHash() =>
    r'0ea1a65c72344f735421e0bfa2a118ca35dc8656';

abstract class _$BookmarkController extends BuildlessAutoDisposeNotifier<void> {
  late final String id;

  void build(String id);
}

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.
///
/// Copied from [BookmarkController].
@ProviderFor(BookmarkController)
const bookmarkControllerProvider = BookmarkControllerFamily();

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.
///
/// Copied from [BookmarkController].
class BookmarkControllerFamily extends Family<void> {
  /// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
  /// the same id so widgets reading the flag rebuild.
  ///
  /// Copied from [BookmarkController].
  const BookmarkControllerFamily();

  /// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
  /// the same id so widgets reading the flag rebuild.
  ///
  /// Copied from [BookmarkController].
  BookmarkControllerProvider call(String id) {
    return BookmarkControllerProvider(id);
  }

  @override
  BookmarkControllerProvider getProviderOverride(
    covariant BookmarkControllerProvider provider,
  ) {
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
  String? get name => r'bookmarkControllerProvider';
}

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.
///
/// Copied from [BookmarkController].
class BookmarkControllerProvider
    extends AutoDisposeNotifierProviderImpl<BookmarkController, void> {
  /// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
  /// the same id so widgets reading the flag rebuild.
  ///
  /// Copied from [BookmarkController].
  BookmarkControllerProvider(String id)
    : this._internal(
        () => BookmarkController()..id = id,
        from: bookmarkControllerProvider,
        name: r'bookmarkControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookmarkControllerHash,
        dependencies: BookmarkControllerFamily._dependencies,
        allTransitiveDependencies:
            BookmarkControllerFamily._allTransitiveDependencies,
        id: id,
      );

  BookmarkControllerProvider._internal(
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
  void runNotifierBuild(covariant BookmarkController notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(BookmarkController Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookmarkControllerProvider._internal(
        () => create()..id = id,
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
  AutoDisposeNotifierProviderElement<BookmarkController, void> createElement() {
    return _BookmarkControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookmarkControllerProvider && other.id == id;
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
mixin BookmarkControllerRef on AutoDisposeNotifierProviderRef<void> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BookmarkControllerProviderElement
    extends AutoDisposeNotifierProviderElement<BookmarkController, void>
    with BookmarkControllerRef {
  _BookmarkControllerProviderElement(super.provider);

  @override
  String get id => (origin as BookmarkControllerProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
