import 'storage_service.dart';

/// Local-only bookmark/save flag on an event row.
///
/// Save is **not** a synced event. It's a private retention signal from the
/// viewer that exempts an event (and its referenced media) from the
/// 30-day retention sweep. Toggling it produces no event, no sync traffic,
/// no follower-visible side effect. See Plan 10's "Save (bookmark)" section.
abstract class SaveService {
  Future<bool> isSaved(String eventId);

  Future<void> setSaved(String eventId, bool saved);

  /// Convenience: flip the current flag and return the new state.
  Future<bool> toggle(String eventId);
}

class DefaultSaveService implements SaveService {
  DefaultSaveService(this._storage);

  final StorageService _storage;

  @override
  Future<bool> isSaved(String eventId) => _storage.isEventSaved(eventId);

  @override
  Future<void> setSaved(String eventId, bool saved) =>
      _storage.setEventSaved(eventId, saved);

  @override
  Future<bool> toggle(String eventId) async {
    final next = !await _storage.isEventSaved(eventId);
    await _storage.setEventSaved(eventId, next);
    return next;
  }
}
