import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/clock.dart';
import '../services/comment_service.dart';
import '../services/content_key_service.dart';
import '../services/crypto/key_cache.dart';
import '../services/crypto/publish_lock.dart';
import '../services/crypto_service.dart';
import '../services/mdns_service.dart';
import '../services/mocks/mock_content_key_service.dart';
import '../services/mocks/mock_crypto_service.dart';
import '../services/mocks/mock_mdns_service.dart';
import '../services/mocks/mock_network_service.dart';
import '../services/mocks/mock_signaling_service.dart';
import '../services/mocks/mock_storage_service.dart';
import '../services/mocks/mock_tor_service.dart';
import '../services/network_service.dart';
import '../services/reaction_service.dart';
import '../services/save_service.dart';
import '../services/signaling_service.dart';
import '../services/storage_service.dart';
import '../services/tor_service.dart';

part 'service_providers.g.dart';

@riverpod
CryptoService cryptoService(Ref ref) => MockCryptoService();

@riverpod
ContentKeyService contentKeyService(Ref ref) =>
    MockContentKeyService();

@riverpod
StorageService storageService(Ref ref) => MockStorageService();

@riverpod
TorService torService(Ref ref) => MockTorService();

/// Reactive holder for the local `.onion` address. Updated by `main.dart`
/// after `TorService.createOnionService` returns; watched by
/// `ownEndpoints` so the published connection card picks up the onion
/// endpoint as soon as it's available.
@Riverpod(keepAlive: true)
class OnionAddress extends _$OnionAddress {
  @override
  String? build() => null;
  void set(String? address) => state = address;
}

@riverpod
NetworkService networkService(Ref ref) => MockNetworkService();

/// Default binding is the in-memory mock so tests don't trigger native
/// channel activity. Production code overrides this in `main.dart` with
/// the real `MethodChannelMdnsService`.
@riverpod
MdnsService mdnsService(Ref ref) => MockMdnsService();

@riverpod
SignalingService signalingService(Ref ref) =>
    MockSignalingService();

@riverpod
Clock clock(Ref ref) => const SystemClock();

/// Shared in-memory feed-key cache. Hydrated at launch (main.dart) with
/// the identity's current key + the keys we've received from each follow,
/// then mutated by KeyRotationService and the sync engine. Tests get a
/// fresh empty cache.
@Riverpod(keepAlive: true)
FeedKeyCache feedKeyCache(Ref ref) => FeedKeyCache();

/// Shared mutex serializing post publication against feed-key rotation
/// (Plan 13). All post-publish services and the rotation service must
/// pull from this single instance — without it, a post in flight could
/// be encrypted with a stale key mid-rotation.
@Riverpod(keepAlive: true)
PublishLock publishLock(Ref ref) => PublishLock();

@riverpod
SaveService saveService(Ref ref) =>
    DefaultSaveService(ref.watch(storageServiceProvider));

@riverpod
CommentService commentService(Ref ref) => DefaultCommentService(
      contentKey: ref.watch(contentKeyServiceProvider),
      storage: ref.watch(storageServiceProvider),
      clock: ref.watch(clockProvider),
      identityLookup: () => ref.read(storageServiceProvider).getIdentity(),
      publishLock: ref.watch(publishLockProvider),
    );

@riverpod
ReactionService reactionService(Ref ref) =>
    DefaultReactionService(
      contentKey: ref.watch(contentKeyServiceProvider),
      storage: ref.watch(storageServiceProvider),
      clock: ref.watch(clockProvider),
      identityLookup: () => ref.read(storageServiceProvider).getIdentity(),
      publishLock: ref.watch(publishLockProvider),
    );
