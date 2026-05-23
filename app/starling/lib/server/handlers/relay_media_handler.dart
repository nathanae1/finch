import 'dart:io';

import 'package:shelf/shelf.dart';

import '../../relay/services/relay_storage_service.dart';

/// `GET /media/<hash>` (Relay mode).
///
/// Streams the on-disk encrypted blob the Owner pushed under `hash`.
/// The Relay never decrypted; the blob is byte-identical to what the
/// Owner stored locally.
///
/// 404 if the hash isn't in `served_media` or the file went missing
/// after the row was written (defensive — should not happen during
/// normal operation).
///
/// Returned as a generic `Function` because `shelf_router` invokes it
/// with the path parameter as a second positional arg — matches the
/// social-mode `mediaHandler` signature.
Function relayMediaHandler({required RelayMediaStore mediaStore}) {
  return (Request request, String hash) async {
    if (hash.isEmpty) {
      return Response(400, body: 'missing hash');
    }
    final path = await mediaStore.mediaPath(hash);
    if (path == null) {
      return Response.notFound('media not found');
    }
    final file = File(path);
    final size = await file.length();
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': 'application/octet-stream',
        'content-length': '$size',
      },
    );
  };
}
