import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/clock.dart';
import '../services/comment_service.dart';
import '../services/content_key_service.dart';
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
CryptoService cryptoService(CryptoServiceRef ref) => MockCryptoService();

@riverpod
ContentKeyService contentKeyService(ContentKeyServiceRef ref) =>
    MockContentKeyService();

@riverpod
StorageService storageService(StorageServiceRef ref) => MockStorageService();

@riverpod
TorService torService(TorServiceRef ref) => MockTorService();

@riverpod
NetworkService networkService(NetworkServiceRef ref) => MockNetworkService();

/// Default binding is the in-memory mock so tests don't trigger native
/// channel activity. Production code overrides this in `main.dart` with
/// the real `MethodChannelMdnsService`.
@riverpod
MdnsService mdnsService(MdnsServiceRef ref) => MockMdnsService();

@riverpod
SignalingService signalingService(SignalingServiceRef ref) =>
    MockSignalingService();

@riverpod
Clock clock(ClockRef ref) => const SystemClock();

@riverpod
SaveService saveService(SaveServiceRef ref) =>
    DefaultSaveService(ref.watch(storageServiceProvider));

@riverpod
CommentService commentService(CommentServiceRef ref) => DefaultCommentService(
      contentKey: ref.watch(contentKeyServiceProvider),
      storage: ref.watch(storageServiceProvider),
      clock: ref.watch(clockProvider),
      identityLookup: () => ref.read(storageServiceProvider).getIdentity(),
    );

@riverpod
ReactionService reactionService(ReactionServiceRef ref) =>
    DefaultReactionService(
      contentKey: ref.watch(contentKeyServiceProvider),
      storage: ref.watch(storageServiceProvider),
      clock: ref.watch(clockProvider),
      identityLookup: () => ref.read(storageServiceProvider).getIdentity(),
    );
