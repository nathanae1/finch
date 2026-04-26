// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownEventsHash() => r'e218ca1fb637801506398d15e40dbb6e02f8e62c';

/// All events authored by the current identity, newest-first via storage's
/// default ordering. Plan 06 will layer a richer feed query on top; this
/// minimal provider exists so the post-publish path can invalidate it.
///
/// Copied from [ownEvents].
@ProviderFor(ownEvents)
final ownEventsProvider = AutoDisposeFutureProvider<List<Event>>.internal(
  ownEvents,
  name: r'ownEventsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownEventsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnEventsRef = AutoDisposeFutureProviderRef<List<Event>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
