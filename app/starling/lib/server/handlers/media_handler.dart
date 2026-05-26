import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import '../../services/media/encrypted_media_paths.dart';
import '../../services/storage_service.dart';

/// `GET /media/<hash>` — streamed encrypted blob for a 64-char lowercase
/// hex BLAKE2b-256 hash. Body is the raw `nonce || ciphertext` form on
/// disk; receivers decrypt with the owner's feed key.
///
/// Returned as a generic `Function` because `shelf_router` invokes it with
/// the path parameter as a second positional arg.
Function mediaHandler({
  required StorageService storage,
  required Directory appSupportDir,
}) {
  return (Request request, String hash) async {
    if (!_isValidHash(hash)) {
      return Response(400, body: 'invalid hash');
    }
    final file = await resolveMediaFileForHash(
      storage: storage,
      appSupportDir: appSupportDir,
      hash: hash,
    );
    if (file == null) {
      return Response.notFound('not found');
    }
    final length = await file.length();
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': 'application/octet-stream',
        'content-length': length.toString(),
      },
    );
  };
}

/// Returns the on-disk media file for [hash] iff the storage layer knows
/// about it AND it exists on disk. Used by both the shelf handler (which
/// streams it) and `Libp2pStreamServer` (which reads it into one frame).
Future<File?> resolveMediaFileForHash({
  required StorageService storage,
  required Directory appSupportDir,
  required String hash,
}) async {
  if (!_isValidHash(hash)) return null;
  final cached = await storage.getMedia(hash);
  if (cached == null) return null;
  final file = await resolveMediaFile(appSupportDir, hash);
  if (!await file.exists()) return null;
  return file;
}

/// Convenience for libp2p: load the entire blob into memory. The current
/// libp2p single-frame stream contract means we can't stream large blobs;
/// callers should size their FFI read buffer accordingly. Returns null when
/// the hash is invalid or the blob is unknown.
Future<Uint8List?> readMediaBytes({
  required StorageService storage,
  required Directory appSupportDir,
  required String hash,
}) async {
  final file = await resolveMediaFileForHash(
    storage: storage,
    appSupportDir: appSupportDir,
    hash: hash,
  );
  if (file == null) return null;
  return await file.readAsBytes();
}

final _hexPattern = RegExp(r'^[0-9a-f]+$');

bool _isValidHash(String hash) =>
    hash.length == 64 && _hexPattern.hasMatch(hash);
