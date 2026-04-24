import 'dart:typed_data';

import '../crypto_service.dart';

/// MegOLM-style hash ratchet suffix. Keeps the ratchet output distinct from
/// any other BLAKE2b-256 hash we compute elsewhere.
const _ratchetSuffix = 'finch-ratchet-v1';

/// Advance a feed key to the next epoch.
///
/// `nextKey = BLAKE2b-256(currentKey || "finch-ratchet-v1")`
///
/// This is one-way: knowing `epoch_n` lets you derive `epoch_{n+1}`, but the
/// hash is preimage-resistant so you cannot derive `epoch_{n-1}`.
Uint8List ratchetFeedKey(Uint8List currentKey, CryptoService crypto) {
  final suffix = Uint8List.fromList(_ratchetSuffix.codeUnits);
  final input = Uint8List(currentKey.length + suffix.length);
  input.setRange(0, currentKey.length, currentKey);
  input.setRange(currentKey.length, input.length, suffix);
  return crypto.blake2b256(input);
}

/// Apply the ratchet [delta] times to derive a future epoch key.
///
/// `delta == 0` returns [baseKey] unchanged. Negative deltas are rejected —
/// the ratchet is one-way.
Uint8List deriveEpochKey(
  Uint8List baseKey,
  int delta,
  CryptoService crypto,
) {
  if (delta < 0) {
    throw ArgumentError('delta must be non-negative (ratchet is one-way)');
  }
  var key = baseKey;
  for (var i = 0; i < delta; i++) {
    key = ratchetFeedKey(key, crypto);
  }
  return key;
}
