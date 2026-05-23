import 'dart:io';

import 'package:path/path.dart' as p;

/// Content-addressed, sharded relative path for a media blob.
///
/// Given a 64-char lowercase hex BLAKE2b-256 hash, returns:
///   `media/<first 2 hex chars>/<first 4 hex chars>/<full hash>`
///
/// Two levels of sharding (256 × 256 = 65 536 sub-dirs) keeps any one
/// directory under a few hundred entries even at millions of blobs.
String mediaRelativePath(String hexHash) {
  assert(
    hexHash.length == 64 && _isLowercaseHex(hexHash),
    'expected 64-char lowercase hex hash, got "$hexHash"',
  );
  final l1 = hexHash.substring(0, 2);
  final l2 = hexHash.substring(0, 4);
  return p.join('media', l1, l2, hexHash);
}

/// Resolves the absolute [File] for a media blob under [root], ensuring the
/// parent directory exists. Does not create or touch the file itself.
Future<File> resolveMediaFile(Directory root, String hexHash) async {
  final file = File(p.join(root.path, mediaRelativePath(hexHash)));
  await file.parent.create(recursive: true);
  return file;
}

bool _isLowercaseHex(String s) {
  for (final c in s.codeUnits) {
    final isDigit = c >= 0x30 && c <= 0x39;
    final isLowerAF = c >= 0x61 && c <= 0x66;
    if (!isDigit && !isLowerAF) return false;
  }
  return true;
}
