import 'dart:typed_data';

/// Crockford base32 encoder/decoder.
///
/// Alphabet: `0123456789abcdefghjkmnpqrstvwxyz` (skips `i l o u`).
/// Output is lowercase. Decoding is case-insensitive and normalizes the
/// common look-alikes (`i`,`I`,`l`,`L` → `1`; `o`,`O` → `0`).
///
/// Used for pubkey and event ID string encoding. 32 input bytes produce
/// exactly 52 output characters. No padding.

const String _alphabet = '0123456789abcdefghjkmnpqrstvwxyz';

/// Encode [bytes] as a lowercase Crockford base32 string (no padding).
String crockfordBase32Encode(Uint8List bytes) {
  if (bytes.isEmpty) return '';

  final outLen = (bytes.length * 8 + 4) ~/ 5;
  final out = StringBuffer();

  var buffer = 0;
  var bits = 0;
  for (final byte in bytes) {
    buffer = (buffer << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      final idx = (buffer >> bits) & 0x1f;
      out.writeCharCode(_alphabet.codeUnitAt(idx));
    }
  }
  if (bits > 0) {
    final idx = (buffer << (5 - bits)) & 0x1f;
    out.writeCharCode(_alphabet.codeUnitAt(idx));
  }

  assert(out.length == outLen);
  return out.toString();
}

/// Decode a Crockford base32 string into bytes. Case-insensitive.
/// Throws [FormatException] on illegal characters.
Uint8List crockfordBase32Decode(String encoded) {
  if (encoded.isEmpty) return Uint8List(0);

  final outLen = (encoded.length * 5) ~/ 8;
  final out = Uint8List(outLen);

  var buffer = 0;
  var bits = 0;
  var outIdx = 0;
  for (var i = 0; i < encoded.length; i++) {
    final value = _charValue(encoded.codeUnitAt(i), i);
    buffer = (buffer << 5) | value;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out[outIdx++] = (buffer >> bits) & 0xff;
    }
  }
  return out;
}

int _charValue(int codeUnit, int position) {
  var c = codeUnit;

  // Uppercase → lowercase.
  if (c >= 0x41 && c <= 0x5a) c += 0x20;

  // Lookalike normalization: i, l → 1; o → 0. (u is not normalized.)
  if (c == 0x69 || c == 0x6c) c = 0x31;
  if (c == 0x6f) c = 0x30;

  // Digits 0-9.
  if (c >= 0x30 && c <= 0x39) return c - 0x30;

  // Letters a-z (minus i, l, o, u — the alphabet skips these).
  if (c >= 0x61 && c <= 0x7a) {
    final idx = _alphabet.indexOf(String.fromCharCode(c));
    if (idx >= 0) return idx;
  }

  throw FormatException(
    'Invalid Crockford base32 character at position $position',
    String.fromCharCode(codeUnit),
    position,
  );
}
