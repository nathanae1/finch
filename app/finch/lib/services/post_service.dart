import 'dart:convert';
import 'dart:typed_data';

import '../models/models.dart';
import '../models/protocol_version.dart';
import 'clock.dart';
import 'content_key_service.dart';
import 'media_service.dart';
import 'storage_service.dart';
import 'types.dart';

abstract class PostService {
  /// Create a kind=1 post with optional caption + one compressed photo.
  /// Returns the new event id.
  Future<String> createPost({
    required Uint8List photoBytes,
    required String caption,
  });

  /// Create a kind=6 delete event pointing at [targetEventId]. Returns the
  /// new delete event's id. Does not remove the target row from storage —
  /// feed queries filter by kind=6 refs at read time.
  Future<String> deletePost(String targetEventId);
}

/// Builds signed events, encrypts media, and persists both locally. Does NOT
/// touch the outbound queue — that lands in Plan 07/11.
///
/// Ordering: media file writes happen before DB writes. A crash between a
/// successful file write and the event row insert leaves orphan files (Plan
/// 14's retention sweep), never a ghost event without backing media.
class DefaultPostService implements PostService {
  DefaultPostService({
    required ContentKeyService contentKey,
    required StorageService storage,
    required MediaService media,
    required Clock clock,
    required Future<Identity?> Function() identityLookup,
  })  : _contentKey = contentKey,
        _storage = storage,
        _media = media,
        _clock = clock,
        _identityLookup = identityLookup;

  final ContentKeyService _contentKey;
  final StorageService _storage;
  final MediaService _media;
  final Clock _clock;
  final Future<Identity?> Function() _identityLookup;

  @override
  Future<String> createPost({
    required Uint8List photoBytes,
    required String caption,
  }) async {
    final identity = await _identityLookup();
    if (identity == null) {
      throw StateError('createPost called before identity is loaded');
    }

    final media = await _media.processAndStoreOwnPhoto(
      photoBytes: photoBytes,
      feedKey: identity.feedKey,
    );

    final unsigned = Event(
      version: kFinchProtocolVersion,
      id: '',
      pubkey: identity.pubkey,
      createdAt: _clock.nowUnixSeconds(),
      kind: EventKind.post,
      ref: null,
      content: Uint8List.fromList(utf8.encode(caption)),
      media: [
        MediaRef(
          hash: media.compressedHash,
          mimeType: media.compressedMime,
          size: media.compressedSize,
        ),
      ],
      extensions: const {},
      sig: Uint8List(0),
    );

    final result = _contentKey.signAndEncryptForAudience(
      unsigned,
      Audience.broadcast,
    );
    await _storage.saveEvent(result.signed);
    return result.signed.id;
  }

  @override
  Future<String> deletePost(String targetEventId) async {
    final identity = await _identityLookup();
    if (identity == null) {
      throw StateError('deletePost called before identity is loaded');
    }

    final unsigned = Event(
      version: kFinchProtocolVersion,
      id: '',
      pubkey: identity.pubkey,
      createdAt: _clock.nowUnixSeconds(),
      kind: EventKind.delete,
      ref: targetEventId,
      content: Uint8List(0),
      media: const [],
      extensions: const {},
      sig: Uint8List(0),
    );

    final result = _contentKey.signAndEncryptForAudience(
      unsigned,
      Audience.broadcast,
    );
    await _storage.saveEvent(result.signed);
    return result.signed.id;
  }
}
