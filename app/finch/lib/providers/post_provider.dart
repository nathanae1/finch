import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/post_service.dart';
import 'identity_provider.dart';
import 'media_provider.dart';
import 'service_providers.dart';

part 'post_provider.g.dart';

@riverpod
PostService postService(PostServiceRef ref) {
  return DefaultPostService(
    contentKey: ref.watch(contentKeyServiceProvider),
    storage: ref.watch(storageServiceProvider),
    media: ref.watch(mediaServiceProvider),
    clock: ref.watch(clockProvider),
    identityLookup: () => ref.read(identityControllerProvider.future),
  );
}
