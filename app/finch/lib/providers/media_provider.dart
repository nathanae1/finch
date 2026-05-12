import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/export_service.dart';
import '../services/media_service.dart';
import '../sync/peer_reachability_provider.dart';
import '../sync/remote_media_fetcher.dart';
import 'app_paths_provider.dart';
import 'service_providers.dart';
import 'sync_provider.dart';

part 'media_provider.g.dart';

@riverpod
MediaService mediaService(Ref ref) {
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
RemoteMediaFetcher remoteMediaFetcher(Ref ref) {
  return RemoteMediaFetcher(
    transport: ref.watch(syncTransportProvider),
    mediaService: ref.watch(mediaServiceProvider),
    storage: ref.watch(storageServiceProvider),
    peerFactory: ref.watch(peerConnectionFactoryProvider),
    reachabilityMonitor: ref.watch(peerReachabilityMonitorProvider),
  );
}

@riverpod
ExportService exportService(Ref ref) {
  return ExportService(
    storage: ref.watch(storageServiceProvider),
    crypto: ref.watch(cryptoServiceProvider),
    exportRoot: ref.watch(exportDirectoryProvider.future),
    mediaRoot: ref.watch(appSupportDirectoryProvider.future),
  );
}
