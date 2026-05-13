import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../services/storage/daos/relay_dao.dart';
import '../../services/storage/database.dart';

/// Filesystem layout + I/O for media blobs the Relay serves.
///
/// The Relay never decrypts; this service writes the raw push bytes to
/// disk under a hash-prefix sharded path (`media/<hh>/<hh>/<hash>`) and
/// reads them back for `GET /media/<hash>`. Sharded paths keep any
/// single directory bounded — 65,536 buckets at depth 2 absorbs even an
/// active Owner indefinitely.
///
/// The blob format is the same the Owner stores locally:
/// `nonce(24) || XChaCha20-Poly1305(...)`. The Relay treats it as
/// opaque bytes.
class RelayMediaStore {
  RelayMediaStore({
    required RelayDao dao,
    required String rootDir,
  })  : _dao = dao,
        _rootDir = rootDir;

  final RelayDao _dao;
  final String _rootDir;

  /// Write a pushed blob to disk and register it in `served_media`.
  /// Idempotent on the hash — re-pushing the same hash overwrites.
  Future<void> putMedia({
    required String hash,
    required Uint8List bytes,
    required int createdAt,
  }) async {
    final path = _resolvePath(hash);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    await _dao.writeServedMedia(
      ServedMediaEntriesCompanion.insert(
        hash: hash,
        size: bytes.length,
        createdAt: createdAt,
        path: path,
      ),
    );
  }

  /// Returns the on-disk path for [hash] if the Relay has it stored,
  /// otherwise null. Callers do their own readAsBytes — streaming the
  /// file straight to the response is preferable to buffering all of it.
  Future<String?> mediaPath(String hash) async {
    final row = await _dao.getServedMedia(hash);
    if (row == null) return null;
    final file = File(row.path);
    if (!await file.exists()) {
      // DB row points at a missing file. Surface as "not found" rather
      // than throwing — the Owner will re-push on next backfill.
      return null;
    }
    return row.path;
  }

  /// Total bytes stored across all media. Used for `/status` and the
  /// dashboard's "Storage" row.
  Future<int> totalBytes() => _dao.servedMediaBytesTotal();

  /// Wipe every blob this Relay has stored — invoked from "Unpair" to
  /// return the Relay to its pre-pair state.
  Future<void> wipe() async {
    final dir = Directory(p.join(_rootDir, 'media'));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await _dao.clearServedMedia();
  }

  String _resolvePath(String hash) {
    // Two two-character buckets sourced from the hash. We use lowercase
    // for filesystem consistency; the wire spec is already case-pinned
    // (Crockford base32 lowercase).
    final lower = hash.toLowerCase();
    final a = lower.length >= 2 ? lower.substring(0, 2) : '00';
    final b = lower.length >= 4 ? lower.substring(2, 4) : '00';
    return p.join(_rootDir, 'media', a, b, lower);
  }
}
