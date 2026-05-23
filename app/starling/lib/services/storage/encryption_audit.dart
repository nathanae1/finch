import 'dart:io';
import 'dart:typed_data';

/// Runtime / debug checks that verify the on-disk shape of storage actually
/// looks encrypted. None of these decrypt anything — they just inspect the
/// header bytes (or attempted reads) for the absence of plaintext markers.
///
/// Used by:
///   * `test/services/storage/encryption_audit_test.dart` — pinned by CI.
///   * The Storage settings screen (debug builds) for manual confirmation.
class EncryptionAudit {
  /// SQLite plaintext files start with the literal ASCII string
  /// "SQLite format 3\0" in the first 16 bytes. SQLCipher overwrites the
  /// header along with the rest of the page, so a properly encrypted DB
  /// file must NOT begin with this magic.
  static const List<int> _sqliteMagic = <int>[
    0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
    0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
  ];

  static const int _maxHeaderBytes = 16;

  /// Read the first 16 bytes of [dbFile] and verify they don't match the
  /// SQLite plaintext magic. Returns `true` if the file looks encrypted
  /// (or is empty / missing — those aren't audit failures, just nothing
  /// to assert).
  static Future<bool> dbLooksEncrypted(File dbFile) async {
    if (!dbFile.existsSync()) return true;
    final raf = await dbFile.open();
    try {
      final size = await raf.length();
      if (size < _sqliteMagic.length) return true;
      final bytes = await raf.read(_sqliteMagic.length);
      return !_startsWith(bytes, _sqliteMagic);
    } finally {
      await raf.close();
    }
  }

  /// Walk every regular file under [mediaRoot] and confirm none of them
  /// look like an unencrypted JPEG/PNG/WebP/GIF. Returns the list of
  /// offending file paths — empty means audit passed.
  static Future<List<String>> findPlaintextMediaFiles(
    Directory mediaRoot,
  ) async {
    final offenders = <String>[];
    if (!mediaRoot.existsSync()) return offenders;

    await for (final entity in mediaRoot.list(recursive: true)) {
      if (entity is! File) continue;
      // Skip the atomic-write tmp files.
      if (entity.path.endsWith('.tmp')) continue;
      if (await _looksLikePlaintextImage(entity)) {
        offenders.add(entity.path);
      }
    }
    return offenders;
  }

  /// Synchronous header check for a single byte array. Used by tests.
  static bool bytesLookLikePlaintextImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF: "GIF8"
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP: starts with "RIFF" then 4 bytes size then "WEBP" — check RIFF
    // and the WEBP marker at offset 8.
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  static Future<bool> _looksLikePlaintextImage(File file) async {
    final raf = await file.open();
    try {
      final length = await raf.length();
      if (length < 4) return false;
      final read = length < _maxHeaderBytes ? length : _maxHeaderBytes;
      final bytes = await raf.read(read);
      return bytesLookLikePlaintextImage(bytes);
    } finally {
      await raf.close();
    }
  }

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}
