import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'service_providers.dart';

part 'bookmark_provider.g.dart';

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.
@riverpod
Future<bool> eventSaved(EventSavedRef ref, String id) async {
  final save = ref.watch(saveServiceProvider);
  return save.isSaved(id);
}

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.
@riverpod
class BookmarkController extends _$BookmarkController {
  @override
  void build(String id) {}

  Future<void> toggle() async {
    await ref.read(saveServiceProvider).toggle(id);
    ref.invalidate(eventSavedProvider(id));
  }
}
