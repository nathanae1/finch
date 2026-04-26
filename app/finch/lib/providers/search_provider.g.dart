// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchResultsHash() => r'71a115c44c7fc53a7dce9a3fa56280110d099d93';

/// Filters the feed events (caption substring) and follows (display-name
/// substring) by the current [searchQueryProvider]. Empty query returns
/// empty results so the feed list-view falls back to its normal source.
///
/// Copied from [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider = AutoDisposeFutureProvider<SearchResults>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsRef = AutoDisposeFutureProviderRef<SearchResults>;
String _$searchQueryHash() => r'e1c5350a9cd6d99e2467260cca2c613f11c88299';

/// Local-only search query. Debounced so each keystroke doesn't fan out to
/// a fresh storage scan + UI rebuild.
///
/// Copied from [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
      SearchQuery.new,
      name: r'searchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
