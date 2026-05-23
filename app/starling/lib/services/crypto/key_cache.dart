import 'dart:typed_data';

/// A single cached feed-key entry.
///
/// Represents the "current" epoch key for a pubkey — the key you'd use to
/// encrypt new content (for your own pubkey) or decrypt recently received
/// content (for followed pubkeys). To decrypt older events whose epoch is
/// behind [epoch], derive the older key via [deriveEpochKey] cannot help —
/// you must have stored the older key (handled elsewhere).
class FeedKeyEntry {
  const FeedKeyEntry({required this.key, required this.epoch});

  /// 32-byte epoch key.
  final Uint8List key;

  /// Epoch number this key represents.
  final int epoch;
}

/// In-memory cache of decrypted feed keys, keyed by pubkey (Crockford
/// base32 string).
///
/// Loaded at app launch by the caller (plan 04), cleared on terminate.
/// Avoids per-event key derivation during feed rendering and encryption.
class FeedKeyCache {
  final Map<String, FeedKeyEntry> _entries = {};

  void put(String pubkey, Uint8List key, int epoch) {
    _entries[pubkey] = FeedKeyEntry(key: key, epoch: epoch);
  }

  FeedKeyEntry? get(String pubkey) => _entries[pubkey];

  bool contains(String pubkey) => _entries.containsKey(pubkey);

  void remove(String pubkey) {
    _entries.remove(pubkey);
  }

  void clear() {
    _entries.clear();
  }

  int get length => _entries.length;
}
