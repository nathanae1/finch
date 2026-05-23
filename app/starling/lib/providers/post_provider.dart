import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/post_service.dart';
import 'identity_provider.dart';
import 'media_provider.dart';
import 'service_providers.dart';
import 'sync_provider.dart';

part 'post_provider.g.dart';

@riverpod
PostService postService(Ref ref) {
  return DefaultPostService(
    contentKey: ref.watch(contentKeyServiceProvider),
    crypto: ref.watch(cryptoServiceProvider),
    storage: ref.watch(storageServiceProvider),
    media: ref.watch(mediaServiceProvider),
    clock: ref.watch(clockProvider),
    identityLookup: () => ref.read(identityControllerProvider.future),
    fanout: ref.watch(postFanoutServiceProvider),
    publishLock: ref.watch(publishLockProvider),
  );
}
