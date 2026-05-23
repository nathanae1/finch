import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/identity_provider.dart';
import '../providers/media_provider.dart';
import '../providers/service_providers.dart';
import '../providers/sync_provider.dart';
import '../services/crypto/feed_key_ratchet.dart';
import '../services/media_service.dart';
import '../sync/key_refresh_throttle.dart';
import '../theme/starling_theme.dart';

/// Decrypts a media blob (by hash) for the given author pubkey and renders
/// it. The author's feed key is resolved transparently — own posts use the
/// identity feed key, others use the cached `Follow.feedKey` row.
///
/// Caches up to [_kMaxCachedDecodedImages] decoded plaintexts in memory using
/// a LRU policy so scrolling back to a previously-viewed post doesn't re-hit
/// the disk. The cache is process-local and cleared on app terminate via
/// normal isolate shutdown.
class EncryptedImage extends ConsumerStatefulWidget {
  const EncryptedImage({
    super.key,
    required this.hash,
    required this.pubkey,
    required this.msgSeq,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.borderRadius,
  });

  final String hash;
  final String pubkey;
  // Per-message sequence of the post this media belongs to. Combined
  // with one of the candidate chain roots via `deriveMsgKey`, it
  // re-derives the AEAD key the publisher used to encrypt the blob.
  // Nullable for legacy rows authored before the v9 schema upgrade —
  // those won't decrypt, render the placeholder.
  final int? msgSeq;
  final BoxFit fit;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  @override
  ConsumerState<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends ConsumerState<EncryptedImage> {
  Uint8List? _bytes;
  bool _missing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant EncryptedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hash != widget.hash || oldWidget.pubkey != widget.pubkey) {
      setState(() {
        _bytes = null;
        _missing = false;
      });
      _loadIfNeeded();
    }
  }

  Future<void> _loadIfNeeded() async {
    final cached = _imageCache.get(widget.hash);
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }
    if (_loading) return;
    _loading = true;
    try {
      final bytes = await _resolveAndDecrypt();
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _missing = true);
      } else {
        _imageCache.put(widget.hash, bytes);
        setState(() => _bytes = bytes);
      }
    } finally {
      _loading = false;
    }
  }

  Future<Uint8List?> _resolveAndDecrypt() async {
    final candidates = await _candidateFeedKeys();
    if (candidates.isEmpty) return null;
    final mediaService = ref.read(mediaServiceProvider);
    final local = await _tryDecryptWithAny(mediaService, candidates);
    if (local != null) return local;

    // Try fetching the encrypted blob. RemoteMediaFetcher returns null
    // both for "already cached on disk" and "no peer reachable" — we
    // can't tell which, so we decrypt again unconditionally below.
    final fetcher = ref.read(remoteMediaFetcherProvider);
    await fetcher.fetch(widget.hash, widget.pubkey);
    final afterFetch = await _tryDecryptWithAny(mediaService, candidates);
    if (afterFetch != null) return afterFetch;

    // Two decrypt attempts under the cached key failed. Either:
    //  - the blob was cached from a previous session under a different
    //    feed-key epoch, or
    //  - the peer rotated their feed key and the rotation hasn't
    //    reached us yet.
    // Pull a one-shot sync (which inlines any pending rotation via the
    // manifest), then retry decrypt once with the refreshed candidate
    // list. Throttled per-peer so a screen full of stale media doesn't
    // fan out into dozens of redundant manifest calls.
    return _refreshKeyAndRetry(mediaService);
  }

  Future<Uint8List?> _refreshKeyAndRetry(MediaService mediaService) async {
    final throttle = ref.read(keyRefreshThrottleProvider);
    final clock = ref.read(clockProvider);
    if (!throttle.tryAcquire(widget.pubkey)) {
      // Already attempted recently — record the staleness signal and
      // give up for this round; the cooldown will lapse in due course.
      await _recordDecryptFailure(clock.nowUnixSeconds());
      return null;
    }
    developer.log(
      'media decrypt failed for ${widget.pubkey}; refreshing feed key',
      name: 'encrypted_image',
    );
    try {
      await ref.read(syncEngineProvider).syncOnePeerByPubkey(widget.pubkey);
    } catch (e) {
      developer.log(
        'feed-key refresh sync failed for ${widget.pubkey}: $e',
        name: 'encrypted_image',
      );
    }
    if (!mounted) return null;
    final refreshed = await _candidateFeedKeys();
    if (refreshed.isEmpty) return null;
    final retry = await _tryDecryptWithAny(mediaService, refreshed);
    if (retry != null) return retry;
    await _recordDecryptFailure(clock.nowUnixSeconds());
    return null;
  }

  Future<void> _recordDecryptFailure(int now) async {
    // Stamp the staleness signal on the follow row so connection
    // settings can show "Key — stale" and ops can spot the gap.
    // Skip for own-pubkey: we never look up our own row that way, and
    // a same-app self-decrypt mismatch is a different bug class.
    final identity = await ref.read(identityControllerProvider.future);
    if (identity != null && identity.pubkey == widget.pubkey) return;
    final storage = ref.read(storageServiceProvider);
    await storage.setLastDecryptFailureAt(widget.pubkey, now);
  }

  /// Walks [chainRoots] in priority order, derives the per-message AEAD
  /// key from each one (using the post's `msgSeq` from the widget arg),
  /// and tries to decrypt. Returns the first plaintext that comes
  /// through, or null if everything failed.
  ///
  /// A libsodium failure on any one root is expected when the blob was
  /// encrypted under a different epoch's chain root — keep going until
  /// something works.
  Future<Uint8List?> _tryDecryptWithAny(
    MediaService mediaService,
    List<Uint8List> chainRoots,
  ) async {
    final msgSeq = widget.msgSeq;
    if (msgSeq == null) {
      // Legacy / pre-v9 row with no msg_seq stored — there's no way to
      // derive the key. Fall through to the placeholder.
      developer.log(
        'no msgSeq for media ${widget.hash} (pubkey=${widget.pubkey})',
        name: 'encrypted_image',
      );
      return null;
    }
    final crypto = ref.read(cryptoServiceProvider);
    for (final root in chainRoots) {
      final msgKey = deriveMsgKey(root, msgSeq, crypto);
      _logImg(
        'dec deriveMsgKey hash=${_shortHexImg(widget.hash)} '
        'pubkey=${widget.pubkey} msgSeq=$msgSeq '
        'rootFp=${_shortFpImg(root)} msgKeyFp=${_shortFpImg(msgKey)}',
      );
      try {
        final bytes = await mediaService.readPlaintext(widget.hash, msgKey);
        if (bytes != null) return bytes;
      } catch (_) {
        // Wrong key — try the next chain root.
        continue;
      }
    }
    developer.log(
      'no candidate key decrypted media ${widget.hash} '
      '(pubkey=${widget.pubkey}, msgSeq=$msgSeq, '
      'tried=${chainRoots.length})',
      name: 'encrypted_image',
    );
    return null;
  }

  /// Returns the chain roots to try when decrypting this media, in
  /// priority order. For own posts: current identity feed key first,
  /// then retired keys (Plan 13 history). For followee posts: current
  /// `Follow.feedKey` first, then archived chain roots from
  /// `follow_feed_key_history` covering the post's createdAt window.
  Future<List<Uint8List>> _candidateFeedKeys() async {
    final identity = await ref.read(identityControllerProvider.future);
    final storage = ref.read(storageServiceProvider);
    if (identity != null && identity.pubkey == widget.pubkey) {
      final history = await storage.getFeedKeyHistory();
      // Newest retired first — recent posts are far more common than
      // ancient ones, so this minimises wasted decrypt attempts.
      history.sort((a, b) => b.validUntil.compareTo(a.validUntil));
      return [identity.feedKey, ...history.map((r) => r.feedKey)];
    }
    final follow = await storage.getFollow(widget.pubkey);
    if (follow == null) return const [];
    final history = await storage.getFollowFeedKeyHistory(widget.pubkey);
    history.sort((a, b) => b.validUntil.compareTo(a.validUntil));
    return [follow.feedKey, ...history.map((r) => r.feedKey)];
  }

  Future<void> _retry() async {
    setState(() => _missing = false);
    await _loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final starling = StarlingTheme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.zero;

    Widget content;
    if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    } else if (_missing) {
      content = _PlaceholderTile(
        background: starling.colors.linen,
        label: 'Tap to load',
        labelColor: starling.colors.graphite,
        onTap: _retry,
      );
    } else {
      content = _PlaceholderTile(
        background: starling.colors.linen,
        labelColor: starling.colors.stone,
      );
    }

    final clipped = ClipRRect(
      borderRadius: radius,
      child: content,
    );

    if (widget.aspectRatio != null) {
      return AspectRatio(aspectRatio: widget.aspectRatio!, child: clipped);
    }
    return clipped;
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({
    required this.background,
    this.label,
    this.labelColor,
    this.onTap,
  });

  final Color background;
  final String? label;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      color: background,
      alignment: Alignment.center,
      child: label == null
          ? null
          : Text(
              label!,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontFamily: 'IBMPlexSans',
                fontWeight: FontWeight.w500,
              ),
            ),
    );
    if (onTap == null) return tile;
    return GestureDetector(onTap: onTap, child: tile);
  }
}

const _kMaxCachedDecodedImages = 50;

/// Process-local LRU cache for decoded image plaintexts. Exposed via
/// [resetEncryptedImageCacheForTesting] so tests can isolate.
final _imageCache = _LruImageCache(_kMaxCachedDecodedImages);

@visibleForTesting
void resetEncryptedImageCacheForTesting() => _imageCache.clear();

class _LruImageCache {
  _LruImageCache(this._capacity);

  final int _capacity;
  final LinkedHashMap<String, Uint8List> _entries =
      LinkedHashMap<String, Uint8List>();

  Uint8List? get(String key) {
    final v = _entries.remove(key);
    if (v == null) return null;
    _entries[key] = v;
    return v;
  }

  void put(String key, Uint8List value) {
    if (_entries.containsKey(key)) {
      _entries.remove(key);
    } else if (_entries.length >= _capacity) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = value;
  }

  void clear() => _entries.clear();
}

String _shortHexImg(String hex) {
  if (hex.length <= 8) return hex;
  return '${hex.substring(0, 8)}…';
}

String _shortFpImg(Uint8List bytes) {
  final hex = bytes
      .take(4)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '$hex…';
}

void _logImg(String msg) {
  // ignore: avoid_print
  print('[starling.media] $msg');
}
