import 'dart:io';

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
    final cached = await storage.getMedia(hash);
    if (cached == null) {
      return Response.notFound('not found');
    }
    final file = await resolveMediaFile(appSupportDir, hash);
    if (!await file.exists()) {
      return Response.notFound('not found');
    }
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': 'application/octet-stream',
        'content-length': cached.size.toString(),
      },
    );
  };
}

final _hexPattern = RegExp(r'^[0-9a-f]+$');

bool _isValidHash(String hash) =>
    hash.length == 64 && _hexPattern.hasMatch(hash);
