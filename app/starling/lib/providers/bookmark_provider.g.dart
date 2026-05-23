// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.

@ProviderFor(eventSaved)
final eventSavedProvider = EventSavedFamily._();

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.

final class EventSavedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the local viewer has bookmarked (saved) the post with [id].
  /// Local-only — never produces a synced event. See Plan 10's Save discussion.
  EventSavedProvider._({
    required EventSavedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventSavedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventSavedHash();

  @override
  String toString() {
    return r'eventSavedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return eventSaved(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventSavedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventSavedHash() => r'3865267031314ef5e23a1587c89bd5ae114941fa';

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.

final class EventSavedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  EventSavedFamily._()
    : super(
        retry: null,
        name: r'eventSavedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the local viewer has bookmarked (saved) the post with [id].
  /// Local-only — never produces a synced event. See Plan 10's Save discussion.

  EventSavedProvider call(String id) =>
      EventSavedProvider._(argument: id, from: this);

  @override
  String toString() => r'eventSavedProvider';
}

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.

@ProviderFor(BookmarkController)
final bookmarkControllerProvider = BookmarkControllerFamily._();

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.
final class BookmarkControllerProvider
    extends $NotifierProvider<BookmarkController, void> {
  /// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
  /// the same id so widgets reading the flag rebuild.
  BookmarkControllerProvider._({
    required BookmarkControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookmarkControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookmarkControllerHash();

  @override
  String toString() {
    return r'bookmarkControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookmarkController create() => BookmarkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookmarkControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookmarkControllerHash() =>
    r'ee7a9f787cb15f1e9cc10483be81dbd694c7fa9e';

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.

final class BookmarkControllerFamily extends $Family
    with $ClassFamilyOverride<BookmarkController, void, void, void, String> {
  BookmarkControllerFamily._()
    : super(
        retry: null,
        name: r'bookmarkControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
  /// the same id so widgets reading the flag rebuild.

  BookmarkControllerProvider call(String id) =>
      BookmarkControllerProvider._(argument: id, from: this);

  @override
  String toString() => r'bookmarkControllerProvider';
}

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.

abstract class _$BookmarkController extends $Notifier<void> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  void build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
