import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../server/http_server.dart';
import 'app_paths_provider.dart';
import 'follow_provider.dart';
import 'identity_provider.dart';
import 'service_providers.dart';

part 'server_provider.g.dart';

/// Lifecycle owner for the embedded [FinchHttpServer]. The published
/// state is the bound port (or `null` while pre-onboarding / stopped),
/// so consumers like Plan 09 (mDNS) and Plan 11 (Tor) can `ref.watch` it.
@riverpod
class HttpServerController extends _$HttpServerController {
  FinchHttpServer? _server;

  @override
  Future<int?> build() async {
    final identityAsync = ref.watch(identityControllerProvider);
    final identity = identityAsync.value;
    if (identity == null) return null;

    final storage = ref.watch(storageServiceProvider);
    final contentKey = ref.watch(contentKeyServiceProvider);
    final clock = ref.watch(clockProvider);
    final appSupportDir = await ref.watch(appSupportDirectoryProvider.future);

    final server = FinchHttpServer.social(
      storage: storage,
      contentKey: contentKey,
      identityLookup: storage.getIdentity,
      appSupportDir: appSupportDir,
      clock: clock,
      // Lazy lookup avoids a build-time cycle:
      //   ownEndpoints → httpServerController → followService → ownEndpoints.
      // followService is only needed at /follow-accept request time.
      followServiceLookup: () => ref.read(followServiceProvider),
    );
    await server.start();
    _server = server;
    ref.onDispose(() async {
      await server.stop();
      _server = null;
    });
    return server.port;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.stop();
    }
    state = const AsyncData(null);
  }

  Future<void> restart() async {
    await stop();
    ref.invalidateSelf();
  }
}
