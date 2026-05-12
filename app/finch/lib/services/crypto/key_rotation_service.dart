import 'dart:typed_data';

import '../clock.dart';
import '../content_key_service.dart';
import '../crypto_service.dart';
import '../storage_service.dart';
import 'crockford_base32.dart';
import 'key_cache.dart';
import 'publish_lock.dart';

/// Generates a new feed key and distributes it to remaining followers when
/// a follower is removed (Plan 13).
///
/// Steps for `rotate(removedPubkey: X)`:
///   1. Append the current key to `feed_key_history` with the half-open
///      window `[identity.feedKeyValidFrom, now)`.
///   2. Generate a fresh 256-bit key, set it as `identity.feedKey` with
///      `feedKeyEpoch = 0` and `feedKeyValidFrom = now`. Update the
///      [FeedKeyCache] entry for our own pubkey.
///   3. For each remaining accepted inbound follower (excluding X): derive
///      the X25519 DH shared key and encrypt the new feed key, recording
///      the wrapped payload + nonce in `pending_key_distributions`.
///   4. Defensively clear any pending distributions that still target X.
///
/// The whole rotation runs under a [PublishLock] shared with the publish
/// path so a post in flight can't observe a torn state. Concurrent
/// `rotate()` calls serialize.
class KeyRotationService {
  KeyRotationService({
    required CryptoService crypto,
    required ContentKeyService contentKey,
    required StorageService storage,
    required Clock clock,
    required FeedKeyCache feedKeyCache,
    required PublishLock publishLock,
    required Future<Uint8List?> Function() ownSecretKeyLookup,
  })  : _crypto = crypto,
        _contentKey = contentKey,
        _storage = storage,
        _clock = clock,
        _feedKeyCache = feedKeyCache,
        _publishLock = publishLock,
        _ownSecretKeyLookup = ownSecretKeyLookup;

  final CryptoService _crypto;
  final ContentKeyService _contentKey;
  final StorageService _storage;
  final Clock _clock;
  final FeedKeyCache _feedKeyCache;
  final PublishLock _publishLock;
  final Future<Uint8List?> Function() _ownSecretKeyLookup;

  Future<void> rotate({required String removedPubkey}) {
    return _publishLock.synchronized(() => _rotateLocked(removedPubkey));
  }

  Future<void> _rotateLocked(String removedPubkey) async {
    final identity = await _storage.getIdentity();
    if (identity == null) {
      throw StateError('cannot rotate feed key: no identity loaded');
    }
    final secretKey = await _ownSecretKeyLookup();
    if (secretKey == null) {
      throw StateError('cannot rotate feed key: no secret key available');
    }

    final now = _clock.nowUnixSeconds();

    // 1. Retire the current key.
    await _storage.appendFeedKeyHistory(
      feedKey: identity.feedKey,
      feedKeyEpoch: identity.feedKeyEpoch,
      validFrom: identity.feedKeyValidFrom == 0
          ? identity.createdAt
          : identity.feedKeyValidFrom,
      validUntil: now,
    );

    // 2. Generate the new key and persist + cache it. Reset the per-
    //    message sequence counter — fresh chain root means msg_seq
    //    restarts at 0 under the new key.
    final newKey = _crypto.randomBytes(32);
    final newIdentity = identity.copyWith(
      feedKey: newKey,
      feedKeyEpoch: 0,
      feedKeyValidFrom: now,
      msgSeqCounter: 0,
    );
    await _storage.saveIdentity(newIdentity);
    _feedKeyCache.put(identity.pubkey, newKey, 0);

    // 3. Wrap and queue for each remaining follower.
    final myEdPk = crockfordBase32Decode(identity.pubkey);
    final myXSk = _crypto.ed25519ToX25519SecretKey(secretKey);
    final followers = await _storage.getAcceptedFollowerPubkeys();
    for (final followerPubkey in followers) {
      if (followerPubkey == removedPubkey) continue;
      final theirEdPk = crockfordBase32Decode(followerPubkey);
      final theirXPk = _crypto.ed25519ToX25519PublicKey(theirEdPk);
      // Mirror the follow handshake's key-exchange convention: pass
      // `requesterPubkey` as the rotating party (us) and `responderPubkey`
      // as the recipient (the follower). The recipient reverses these to
      // arrive at the same shared key.
      final shared = _crypto.deriveSharedKey(
        myXSk,
        theirXPk,
        myEdPk,
        theirEdPk,
        now,
      );
      final wrapped = _contentKey.encryptFeedKey(newKey, shared);
      // `encryptFeedKey` returns nonce ‖ ciphertext.
      final nonce = Uint8List.fromList(wrapped.sublist(0, 24));
      final encryptedKey = Uint8List.fromList(wrapped.sublist(24));
      await _storage.addPendingKeyDistribution(
        targetPubkey: followerPubkey,
        encryptedFeedKey: encryptedKey,
        nonce: nonce,
        createdAt: now,
      );
    }

    // 4. Sweep stragglers for the removed pubkey.
    await _storage.clearPendingDistributionsFor(removedPubkey);
  }
}
