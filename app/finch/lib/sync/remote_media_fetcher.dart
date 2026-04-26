import 'dart:developer' as developer;
import 'dart:typed_data';

import '../services/media_service.dart';
import '../services/storage_service.dart';
import 'peer_connection_factory.dart';
import 'sync_engine.dart' show SyncTransport;

/// On-demand media pull. Used by `EncryptedImage` when the local cache
/// misses: resolve a peer for the author, fetch `/media/{hash}`, persist
/// to disk, then let the widget read it back via `MediaService`.
///
/// Returns the raw encrypted bytes on success, `null` if the author has no
/// reachable peer right now (caller decides whether to show a placeholder
/// or retry on the next sync).
class RemoteMediaFetcher {
  RemoteMediaFetcher({
    required SyncTransport transport,
    required MediaService mediaService,
    required StorageService storage,
    required PeerConnectionFactory peerFactory,
  })  : _transport = transport,
        _mediaService = mediaService,
        _storage = storage,
        _peerFactory = peerFactory;

  final SyncTransport _transport;
  final MediaService _mediaService;
  final StorageService _storage;
  final PeerConnectionFactory _peerFactory;

  /// Fetches and persists the encrypted blob for [hash] from a peer that
  /// owns [authorPubkey]. Returns the encrypted bytes; the caller can
  /// then read the plaintext through `MediaService.readPlaintext`.
  Future<Uint8List?> fetch(String hash, String authorPubkey) async {
    // Cache hit short-circuit. The widget already checks this, but
    // calling fetch() directly should be safe.
    final cached = await _storage.getMedia(hash);
    if (cached != null) {
      return null;
    }

    final connection = _peerFactory.buildLanConnection(authorPubkey);
    if (connection == null) return null;

    final Uint8List bytes;
    try {
      bytes = await _transport.fetchMedia(connection, hash);
    } catch (e) {
      developer.log(
        'media fetch failed for $hash from $authorPubkey: $e',
        name: 'remote_media_fetcher',
      );
      return null;
    }

    try {
      await _mediaService.storeReceivedBlob(hash, bytes);
    } catch (e) {
      developer.log(
        'media store failed for $hash: $e',
        name: 'remote_media_fetcher',
      );
      return null;
    }
    return bytes;
  }
}
