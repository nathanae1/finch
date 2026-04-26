import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/types.dart';
import 'identity_provider.dart';
import 'server_provider.dart';
import 'service_providers.dart';

part 'discovery_provider.g.dart';

/// Owns the mDNS lifecycle. Once both the identity is loaded and the HTTP
/// server has bound a port, registers the `_finch._tcp` service and
/// streams the live peer cache. Disposes by deregistering.
///
/// The published value is the current peer map (keyed by peer pubkey).
/// Pull-to-refresh in the feed can call [DiscoveryController.rescan] to
/// trigger a fresh browse round.
@riverpod
class DiscoveryController extends _$DiscoveryController {
  StreamSubscription<Map<String, LanPeer>>? _sub;
  bool _registered = false;

  @override
  Future<Map<String, LanPeer>> build() async {
    final identityAsync = ref.watch(identityControllerProvider);
    final identity = identityAsync.value;
    final port = await ref.watch(httpServerControllerProvider.future);
    final mdns = ref.watch(mdnsServiceProvider);

    if (identity == null || port == null) {
      return mdns.currentPeers();
    }

    await mdns.register(pubkey: identity.pubkey, port: port);
    _registered = true;

    unawaited(_sub?.cancel());
    _sub = mdns.peers.listen(
      (peers) => state = AsyncData(peers),
      onError: (Object e, StackTrace st) {
        // Swallow stream errors; the cache stays at its last value and
        // the next register/rescan will refill it.
      },
    );

    ref.onDispose(() {
      unawaited(_sub?.cancel());
      _sub = null;
      if (_registered) {
        _registered = false;
        unawaited(mdns.deregister());
      }
    });

    return mdns.currentPeers();
  }

  Future<void> rescan() async {
    final mdns = ref.read(mdnsServiceProvider);
    await mdns.rescan();
  }
}
