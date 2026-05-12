// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All events authored by the current identity, newest-first via storage's
/// default ordering. Plan 06 will layer a richer feed query on top; this
/// minimal provider exists so the post-publish path can invalidate it.

@ProviderFor(ownEvents)
final ownEventsProvider = OwnEventsProvider._();

/// All events authored by the current identity, newest-first via storage's
/// default ordering. Plan 06 will layer a richer feed query on top; this
/// minimal provider exists so the post-publish path can invalidate it.

final class OwnEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// All events authored by the current identity, newest-first via storage's
  /// default ordering. Plan 06 will layer a richer feed query on top; this
  /// minimal provider exists so the post-publish path can invalidate it.
  OwnEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    return ownEvents(ref);
  }
}

String _$ownEventsHash() => r'52ae62a4503465cd095333ade4a4090a019e4abb';
