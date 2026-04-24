import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// 24-word BIP-39 recovery phrase derivation.
///
/// **Note:** Uses BLAKE2b-256 for the 8-bit checksum instead of SHA-256 so
/// the entire crypto stack stays in libsodium (no extra crypto deps). This
/// makes Finch recovery phrases **not interoperable** with standard BIP-39
/// tools (hardware wallets, other BIP-39 clients) — a phrase written down
/// from Finch can only be restored in another Finch installation.
///
/// Entropy is 256 bits (32 bytes), checksum is 8 bits → 264 bits → 24 × 11
/// bits, one word each from the 2048-word English word list.
class RecoveryPhrase {
  RecoveryPhrase._();

  static List<String>? _words;
  static Map<String, int>? _wordIndex;

  /// Load the word list from `assets/bip39_english.txt`. Cached after first
  /// call. Safe to call repeatedly.
  static Future<void> _ensureLoaded() async {
    if (_words != null) return;
    final raw = await rootBundle.loadString('assets/bip39_english.txt');
    final words = raw
        .split('\n')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.length != 2048) {
      throw StateError(
        'BIP-39 word list must have 2048 entries, got ${words.length}',
      );
    }
    _words = words;
    _wordIndex = {for (var i = 0; i < words.length; i++) words[i]: i};
  }

  /// Encode a 32-byte seed as a 24-word mnemonic.
  ///
  /// [blake2b256] is injected so this module doesn't depend on
  /// `SodiumCryptoService` (which would create a circular import). Pass the
  /// same hash used elsewhere in the app.
  static Future<List<String>> toWords(
    Uint8List seed,
    Uint8List Function(Uint8List) blake2b256,
  ) async {
    if (seed.length != 32) {
      throw ArgumentError('seed must be 32 bytes, got ${seed.length}');
    }
    await _ensureLoaded();
    final words = _words!;

    // Compute checksum: first byte of BLAKE2b-256(seed). Take the high 8 bits.
    final checksum = blake2b256(seed)[0];

    // Build a 264-bit bitstream: 256 bits of seed + 8 checksum bits.
    final bits = Uint8List(33);
    bits.setRange(0, 32, seed);
    bits[32] = checksum;

    // Read 24 × 11-bit groups.
    final result = <String>[];
    for (var i = 0; i < 24; i++) {
      final idx = _readBits(bits, i * 11, 11);
      result.add(words[idx]);
    }
    return result;
  }

  /// Decode a 24-word mnemonic back into the 32-byte seed.
  ///
  /// Throws [ArgumentError] if the word count is wrong, a word is not in
  /// the list, or the checksum is invalid.
  static Future<Uint8List> toSeed(
    List<String> words,
    Uint8List Function(Uint8List) blake2b256,
  ) async {
    if (words.length != 24) {
      throw ArgumentError(
        'recovery phrase must be 24 words, got ${words.length}',
      );
    }
    await _ensureLoaded();
    final index = _wordIndex!;

    final bits = Uint8List(33);
    for (var i = 0; i < 24; i++) {
      final word = words[i].toLowerCase().trim();
      final wordIdx = index[word];
      if (wordIdx == null) {
        throw ArgumentError('unknown word in recovery phrase: "${words[i]}"');
      }
      _writeBits(bits, i * 11, 11, wordIdx);
    }

    final seed = Uint8List.fromList(bits.sublist(0, 32));
    final checksum = bits[32];
    final expected = blake2b256(seed)[0];
    if (checksum != expected) {
      throw ArgumentError('recovery phrase checksum mismatch');
    }
    return seed;
  }
}

/// Read [length] bits (up to 16) starting at [offset] from a big-endian
/// bitstream stored in [bytes]. MSB first.
int _readBits(Uint8List bytes, int offset, int length) {
  var result = 0;
  for (var i = 0; i < length; i++) {
    final bitOffset = offset + i;
    final byte = bytes[bitOffset >> 3];
    final bit = (byte >> (7 - (bitOffset & 7))) & 1;
    result = (result << 1) | bit;
  }
  return result;
}

/// Write the low [length] bits of [value] into [bytes] starting at [offset],
/// MSB first.
void _writeBits(Uint8List bytes, int offset, int length, int value) {
  for (var i = 0; i < length; i++) {
    final bit = (value >> (length - 1 - i)) & 1;
    final bitOffset = offset + i;
    final byteIdx = bitOffset >> 3;
    final bitIdx = 7 - (bitOffset & 7);
    if (bit == 1) {
      bytes[byteIdx] |= 1 << bitIdx;
    } else {
      bytes[byteIdx] &= ~(1 << bitIdx) & 0xff;
    }
  }
}
