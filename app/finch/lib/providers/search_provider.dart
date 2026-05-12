import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/models.dart';
import '../services/types.dart';
import 'feed_provider.dart';
import 'service_providers.dart';

part 'search_provider.g.dart';

/// Local-only search query. Debounced so each keystroke doesn't fan out to
/// a fresh storage scan + UI rebuild.
@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void set(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      state = value;
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

class SearchResults {
  const SearchResults({required this.events, required this.follows});
  final List<Event> events;
  final List<Follow> follows;

  bool get isEmpty => events.isEmpty && follows.isEmpty;
}

/// Filters the feed events (caption substring) and follows (display-name
/// substring) by the current [searchQueryProvider]. Empty query returns
/// empty results so the feed list-view falls back to its normal source.
@riverpod
Future<SearchResults> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) {
    return const SearchResults(events: [], follows: []);
  }
  // Subscribe synchronously before any await — using `ref` after an await
  // is illegal if the provider was invalidated during the await.
  final feedFuture = ref.watch(feedProvider.future);
  final storage = ref.watch(storageServiceProvider);
  final feed = await feedFuture;
  final allFollows = await storage.getFollows();

  final matchedEvents = feed.where((e) {
    if (e.content.isEmpty) return false;
    final caption = utf8.decode(e.content, allowMalformed: true).toLowerCase();
    return caption.contains(query);
  }).toList();

  final matchedFollows = allFollows.where((f) {
    final name = (f.displayName ?? '').toLowerCase();
    return name.contains(query);
  }).toList();

  return SearchResults(events: matchedEvents, follows: matchedFollows);
}
