import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/media_service.dart';
import '../sync/remote_media_fetcher.dart';
import 'app_paths_provider.dart';
import 'service_providers.dart';
import 'sync_provider.dart';

part 'media_provider.g.dart';

@riverpod
MediaService mediaService(MediaServiceRef ref) {
  return DefaultMediaService(
    crypto: ref.watch(cryptoServiceProvider),
    storage: ref.watch(storageServiceProvider),
    clock: ref.watch(clockProvider),
    appSupportDir: ref.watch(appSupportDirectoryProvider.future),
  );
}

/// Lazily fetches media from peers when the local cache misses. Used by
/// `EncryptedImage` as a fallback path.
@riverpod
RemoteMediaFetcher remoteMediaFetcher(RemoteMediaFetcherRef ref) {
  return RemoteMediaFetcher(
    transport: ref.watch(lanNetworkServiceProvider),
    mediaService: ref.watch(mediaServiceProvider),
    storage: ref.watch(storageServiceProvider),
    peerFactory: ref.watch(peerConnectionFactoryProvider),
  );
}
