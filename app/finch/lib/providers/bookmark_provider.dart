import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'service_providers.dart';

part 'bookmark_provider.g.dart';

/// Whether the local viewer has bookmarked (saved) the post with [id].
/// Local-only — never produces a synced event. See Plan 10's Save discussion.
@riverpod
Future<bool> eventSaved(EventSavedRef ref, String id) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.isEventSaved(id);
}

/// Toggles `is_saved` on an event row. Invalidates [eventSavedProvider] for
/// the same id so widgets reading the flag rebuild.
@riverpod
class BookmarkController extends _$BookmarkController {
  @override
  void build(String id) {}

  Future<void> toggle() async {
    final storage = ref.read(storageServiceProvider);
    final current = await storage.isEventSaved(id);
    await storage.setEventSaved(id, !current);
    ref.invalidate(eventSavedProvider(id));
  }
}
