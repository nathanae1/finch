// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [PeerConnectionFactory] used by the sync engine
/// and `RemoteMediaFetcher`. Thin façade over [peerReachabilityMonitor]
/// — actual probing and state-tracking lives there.

@ProviderFor(peerConnectionFactory)
final peerConnectionFactoryProvider = PeerConnectionFactoryProvider._();

/// Provides the singleton [PeerConnectionFactory] used by the sync engine
/// and `RemoteMediaFetcher`. Thin façade over [peerReachabilityMonitor]
/// — actual probing and state-tracking lives there.

final class PeerConnectionFactoryProvider
    extends
        $FunctionalProvider<
          PeerConnectionFactory,
          PeerConnectionFactory,
          PeerConnectionFactory
        >
    with $Provider<PeerConnectionFactory> {
  /// Provides the singleton [PeerConnectionFactory] used by the sync engine
  /// and `RemoteMediaFetcher`. Thin façade over [peerReachabilityMonitor]
  /// — actual probing and state-tracking lives there.
  PeerConnectionFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'peerConnectionFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$peerConnectionFactoryHash();

  @$internal
  @override
  $ProviderElement<PeerConnectionFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PeerConnectionFactory create(Ref ref) {
    return peerConnectionFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PeerConnectionFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PeerConnectionFactory>(value),
    );
  }
}

String _$peerConnectionFactoryHash() =>
    r'1ec5d4af777fc9e9ed1306bbfdaa1e0646bab2f2';

/// LanNetworkService singleton. The default `networkServiceProvider` is
/// the abstract interface (mock by default); the concrete LAN client is
/// kept separate so the sync engine can call `fetchEnvelope`, which is a
/// LAN-specific method not yet on the cross-tier interface.
///
/// `keepAlive: true` because the wrapped `http.Client` is a connection-
/// pooling singleton — auto-disposing closes it, and a brief watcher gap
/// during a rebuild cascade (e.g. when `onionAddressProvider` flips
/// non-null and `torNetworkServiceProvider` rebuilds → `syncTransport`
/// rebuilds) used to leave captured references holding a closed client.

@ProviderFor(lanNetworkService)
final lanNetworkServiceProvider = LanNetworkServiceProvider._();

/// LanNetworkService singleton. The default `networkServiceProvider` is
/// the abstract interface (mock by default); the concrete LAN client is
/// kept separate so the sync engine can call `fetchEnvelope`, which is a
/// LAN-specific method not yet on the cross-tier interface.
///
/// `keepAlive: true` because the wrapped `http.Client` is a connection-
/// pooling singleton — auto-disposing closes it, and a brief watcher gap
/// during a rebuild cascade (e.g. when `onionAddressProvider` flips
/// non-null and `torNetworkServiceProvider` rebuilds → `syncTransport`
/// rebuilds) used to leave captured references holding a closed client.

final class LanNetworkServiceProvider
    extends
        $FunctionalProvider<
          LanNetworkService,
          LanNetworkService,
          LanNetworkService
        >
    with $Provider<LanNetworkService> {
  /// LanNetworkService singleton. The default `networkServiceProvider` is
  /// the abstract interface (mock by default); the concrete LAN client is
  /// kept separate so the sync engine can call `fetchEnvelope`, which is a
  /// LAN-specific method not yet on the cross-tier interface.
  ///
  /// `keepAlive: true` because the wrapped `http.Client` is a connection-
  /// pooling singleton — auto-disposing closes it, and a brief watcher gap
  /// during a rebuild cascade (e.g. when `onionAddressProvider` flips
  /// non-null and `torNetworkServiceProvider` rebuilds → `syncTransport`
  /// rebuilds) used to leave captured references holding a closed client.
  LanNetworkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lanNetworkServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lanNetworkServiceHash();

  @$internal
  @override
  $ProviderElement<LanNetworkService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LanNetworkService create(Ref ref) {
    return lanNetworkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LanNetworkService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LanNetworkService>(value),
    );
  }
}

String _$lanNetworkServiceHash() => r'de7cdb89630d19386b31862d1c6224113dfd5cfd';

/// Sibling of [lanNetworkServiceProvider] backed by [TorHttpClient]. Same
/// `LanNetworkService` class, but every HTTP call goes through Arti's
/// SOCKS5 proxy. Returns `null` until our onion address is published —
/// that signal implies the SOCKS port is bound and `tor.init()` has
/// completed, so it doubles as the "Tor is ready for outbound" gate.
///
/// `keepAlive: true` for the same reason as [lanNetworkServiceProvider]:
/// the wrapped `TorHttpClient` is a long-lived resource that should not
/// be torn down on a transient drop in watcher count.

@ProviderFor(torNetworkService)
final torNetworkServiceProvider = TorNetworkServiceProvider._();

/// Sibling of [lanNetworkServiceProvider] backed by [TorHttpClient]. Same
/// `LanNetworkService` class, but every HTTP call goes through Arti's
/// SOCKS5 proxy. Returns `null` until our onion address is published —
/// that signal implies the SOCKS port is bound and `tor.init()` has
/// completed, so it doubles as the "Tor is ready for outbound" gate.
///
/// `keepAlive: true` for the same reason as [lanNetworkServiceProvider]:
/// the wrapped `TorHttpClient` is a long-lived resource that should not
/// be torn down on a transient drop in watcher count.

final class TorNetworkServiceProvider
    extends
        $FunctionalProvider<
          LanNetworkService?,
          LanNetworkService?,
          LanNetworkService?
        >
    with $Provider<LanNetworkService?> {
  /// Sibling of [lanNetworkServiceProvider] backed by [TorHttpClient]. Same
  /// `LanNetworkService` class, but every HTTP call goes through Arti's
  /// SOCKS5 proxy. Returns `null` until our onion address is published —
  /// that signal implies the SOCKS port is bound and `tor.init()` has
  /// completed, so it doubles as the "Tor is ready for outbound" gate.
  ///
  /// `keepAlive: true` for the same reason as [lanNetworkServiceProvider]:
  /// the wrapped `TorHttpClient` is a long-lived resource that should not
  /// be torn down on a transient drop in watcher count.
  TorNetworkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'torNetworkServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$torNetworkServiceHash();

  @$internal
  @override
  $ProviderElement<LanNetworkService?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LanNetworkService? create(Ref ref) {
    return torNetworkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LanNetworkService? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LanNetworkService?>(value),
    );
  }
}

String _$torNetworkServiceHash() => r'cc9fca4ce22ce78cfe308c8546f9f1f91ccc5290';

/// Singleton [SyncTransport] that routes each `PeerConnection` to the
/// HTTP client matching its transport (LAN direct vs SOCKS5-over-Tor).
/// Shared by [syncEngineProvider] and the on-demand media fetcher so
/// they all dial through the same routing logic.

@ProviderFor(syncTransport)
final syncTransportProvider = SyncTransportProvider._();

/// Singleton [SyncTransport] that routes each `PeerConnection` to the
/// HTTP client matching its transport (LAN direct vs SOCKS5-over-Tor).
/// Shared by [syncEngineProvider] and the on-demand media fetcher so
/// they all dial through the same routing logic.

final class SyncTransportProvider
    extends $FunctionalProvider<SyncTransport, SyncTransport, SyncTransport>
    with $Provider<SyncTransport> {
  /// Singleton [SyncTransport] that routes each `PeerConnection` to the
  /// HTTP client matching its transport (LAN direct vs SOCKS5-over-Tor).
  /// Shared by [syncEngineProvider] and the on-demand media fetcher so
  /// they all dial through the same routing logic.
  SyncTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncTransportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncTransportHash();

  @$internal
  @override
  $ProviderElement<SyncTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncTransport create(Ref ref) {
    return syncTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncTransport>(value),
    );
  }
}

String _$syncTransportHash() => r'61e5396ac32df73a3244c2aa498f9360e5fc9353';

/// Best-effort fan-out from the local poster to every accepted follower
/// whose connection is reachable. Used by `DefaultPostService` after a
/// post or delete event is persisted.

@ProviderFor(postFanoutService)
final postFanoutServiceProvider = PostFanoutServiceProvider._();

/// Best-effort fan-out from the local poster to every accepted follower
/// whose connection is reachable. Used by `DefaultPostService` after a
/// post or delete event is persisted.

final class PostFanoutServiceProvider
    extends
        $FunctionalProvider<
          PostFanoutService,
          PostFanoutService,
          PostFanoutService
        >
    with $Provider<PostFanoutService> {
  /// Best-effort fan-out from the local poster to every accepted follower
  /// whose connection is reachable. Used by `DefaultPostService` after a
  /// post or delete event is persisted.
  PostFanoutServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postFanoutServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postFanoutServiceHash();

  @$internal
  @override
  $ProviderElement<PostFanoutService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostFanoutService create(Ref ref) {
    return postFanoutService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostFanoutService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostFanoutService>(value),
    );
  }
}

String _$postFanoutServiceHash() => r'd4dc8b8e8d49a3ebc13f050766055b8536295f40';

/// Catches followers transitioning into a reachable state and pushes
/// recent own events to them. `keepAlive: true` so the in-memory
/// reachable-set + cooldown map survive transient watcher gaps.

@ProviderFor(reconnectPusher)
final reconnectPusherProvider = ReconnectPusherProvider._();

/// Catches followers transitioning into a reachable state and pushes
/// recent own events to them. `keepAlive: true` so the in-memory
/// reachable-set + cooldown map survive transient watcher gaps.

final class ReconnectPusherProvider
    extends
        $FunctionalProvider<ReconnectPusher, ReconnectPusher, ReconnectPusher>
    with $Provider<ReconnectPusher> {
  /// Catches followers transitioning into a reachable state and pushes
  /// recent own events to them. `keepAlive: true` so the in-memory
  /// reachable-set + cooldown map survive transient watcher gaps.
  ReconnectPusherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconnectPusherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconnectPusherHash();

  @$internal
  @override
  $ProviderElement<ReconnectPusher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReconnectPusher create(Ref ref) {
    return reconnectPusher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReconnectPusher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReconnectPusher>(value),
    );
  }
}

String _$reconnectPusherHash() => r'8f4825632466468ecb56e669b6a7ca723ff50597';

/// Routes each peer's HTTP calls to either [lanNetworkServiceProvider]
/// or [torNetworkServiceProvider] based on `connection.transport`.

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

/// Routes each peer's HTTP calls to either [lanNetworkServiceProvider]
/// or [torNetworkServiceProvider] based on `connection.transport`.

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  /// Routes each peer's HTTP calls to either [lanNetworkServiceProvider]
  /// or [torNetworkServiceProvider] based on `connection.transport`.
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'56e197a5d39e5f487c4db683535d076a135f6216';

/// Surfaces sync state to the UI and exposes [syncNow] for pull-to-refresh.

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Surfaces sync state to the UI and exposes [syncNow] for pull-to-refresh.
final class SyncControllerProvider
    extends $NotifierProvider<SyncController, SyncEngineState> {
  /// Surfaces sync state to the UI and exposes [syncNow] for pull-to-refresh.
  SyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngineState>(value),
    );
  }
}

String _$syncControllerHash() => r'777360950e28ada45d24ea34daad140ba4670561';

/// Surfaces sync state to the UI and exposes [syncNow] for pull-to-refresh.

abstract class _$SyncController extends $Notifier<SyncEngineState> {
  SyncEngineState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SyncEngineState, SyncEngineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncEngineState, SyncEngineState>,
              SyncEngineState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
