import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../relay/services/pairing_service.dart';
import '../relay/services/relay_storage_service.dart';
import '../services/clock.dart';
import '../services/content_key_service.dart';
import '../services/crypto_service.dart';
import '../services/follow_service.dart';
import '../services/storage/daos/relay_dao.dart';
import '../services/storage_service.dart';
import '../services/types.dart';
import 'handlers/events_handler.dart';
import 'handlers/events_push_handler.dart';
import 'handlers/follow_accept_handler.dart';
import 'handlers/follow_request_handler.dart';
import 'handlers/manifest_handler.dart';
import 'handlers/media_handler.dart';
import 'handlers/relay_events_handler.dart';
import 'handlers/relay_events_push_handler.dart';
import 'handlers/relay_manifest_handler.dart';
import 'handlers/relay_media_handler.dart';
import 'handlers/relay_media_push_handler.dart';
import 'handlers/relay_pair_handler.dart';
import 'handlers/relay_status_handler.dart';
import 'handlers/status_handler.dart';
import 'middleware/error_handler.dart';
import 'middleware/owner_signature_middleware.dart';
import 'middleware/rate_limit.dart';

/// Embedded shelf HTTP server that exposes content to peers. Binds to a
/// random ephemeral port (49152–65535) and exposes that port via [port]
/// so mDNS (Plan 09) and Tor (Plan 11) can advertise it.
///
/// Two modes:
/// - **social** ([FinchHttpServer.social]): the Owner's phone serving its
///   own content. Mounts the full sync API including the social-mode
///   `POST /events` that decrypts pushes from Followers.
/// - **relay** ([FinchHttpServer.relay]): a desktop install serving the
///   paired Owner's content. Mounts the read-only sync API plus
///   owner-signed `POST /events`, `POST /media`, and the one-shot
///   `POST /pair`. Owner-only writes go through
///   [ownerSignatureMiddleware]; the Relay never decrypts.
class FinchHttpServer {
  FinchHttpServer._({
    required Router Function() buildRouter,
    required Clock clock,
    int maxBindAttempts = 5,
    int rateLimitPerMinute = 120,
    int maxBodyBytes = 1024 * 1024,
    Random? random,
  })  : _buildRouter = buildRouter,
        _clock = clock,
        _maxBindAttempts = maxBindAttempts,
        _rateLimitPerMinute = rateLimitPerMinute,
        _maxBodyBytes = maxBodyBytes,
        _random = random ?? Random.secure();

  factory FinchHttpServer.social({
    required StorageService storage,
    required ContentKeyService contentKey,
    required Future<Identity?> Function() identityLookup,
    required Directory appSupportDir,
    required Clock clock,
    FollowService? followService,
    FollowService? Function()? followServiceLookup,
    int maxBindAttempts = 5,
    int rateLimitPerMinute = 120,
    int maxBodyBytes = 1024 * 1024,
    Random? random,
  }) {
    final lookup = followServiceLookup ?? (() => followService);
    return FinchHttpServer._(
      buildRouter: () => _buildSocialRouter(
        storage: storage,
        contentKey: contentKey,
        identityLookup: identityLookup,
        appSupportDir: appSupportDir,
        clock: clock,
        followServiceLookup: lookup,
      ),
      clock: clock,
      maxBindAttempts: maxBindAttempts,
      rateLimitPerMinute: rateLimitPerMinute,
      maxBodyBytes: maxBodyBytes,
      random: random,
    );
  }

  factory FinchHttpServer.relay({
    required RelayDao relayDao,
    required PairingService pairingService,
    required RelayMediaStore mediaStore,
    required CryptoService crypto,
    required Clock clock,
    required String Function() relayOnion,
    int maxBindAttempts = 5,
    // Bumped from the social default — the Owner's initial backfill push
    // bursts at higher rates than typical Follower fetches.
    int rateLimitPerMinute = 360,
    int maxBodyBytes = 4 * 1024 * 1024,
    Random? random,
  }) {
    return FinchHttpServer._(
      buildRouter: () => _buildRelayRouter(
        relayDao: relayDao,
        pairingService: pairingService,
        mediaStore: mediaStore,
        crypto: crypto,
        clock: clock,
        relayOnion: relayOnion,
      ),
      clock: clock,
      maxBindAttempts: maxBindAttempts,
      rateLimitPerMinute: rateLimitPerMinute,
      maxBodyBytes: maxBodyBytes,
      random: random,
    );
  }

  static const int _portMin = 49152;
  static const int _portMax = 65535;

  final Router Function() _buildRouter;
  final Clock _clock;
  final int _maxBindAttempts;
  final int _rateLimitPerMinute;
  final int _maxBodyBytes;
  final Random _random;

  HttpServer? _server;
  RateLimiter? _rateLimiter;
  int? _port;

  int? get port => _port;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    final rateLimiter = RateLimiter(
      requestsPerMinute: _rateLimitPerMinute,
      clock: _clock,
    );
    final pipeline = const Pipeline()
        .addMiddleware(errorHandlerMiddleware())
        .addMiddleware(rateLimiter.middleware)
        .addMiddleware(bodySizeLimitMiddleware(maxBytes: _maxBodyBytes))
        .addHandler(_buildRouter().call);

    Object? lastError;
    for (var attempt = 0; attempt < _maxBindAttempts; attempt++) {
      final candidate = _portMin + _random.nextInt(_portMax - _portMin + 1);
      try {
        final server = await shelf_io.serve(
          pipeline,
          InternetAddress.anyIPv4,
          candidate,
        );
        _server = server;
        _rateLimiter = rateLimiter;
        _port = candidate;
        return;
      } on SocketException catch (e) {
        lastError = e;
      }
    }
    rateLimiter.dispose();
    throw StateError(
      'could not bind HTTP server after $_maxBindAttempts attempts: '
      '$lastError',
    );
  }

  Future<void> stop() async {
    final server = _server;
    final rateLimiter = _rateLimiter;
    _server = null;
    _rateLimiter = null;
    _port = null;
    rateLimiter?.dispose();
    if (server != null) {
      await server.close(force: true);
    }
  }
}

Router _buildSocialRouter({
  required StorageService storage,
  required ContentKeyService contentKey,
  required Future<Identity?> Function() identityLookup,
  required Directory appSupportDir,
  required Clock clock,
  required FollowService? Function() followServiceLookup,
}) {
  final router = Router();
  router.get(
    '/status',
    statusHandler(
      storage: storage,
      identityLookup: identityLookup,
    ),
  );
  router.get(
    '/manifest',
    manifestHandler(
      storage: storage,
      identityLookup: identityLookup,
    ),
  );
  router.get(
    '/events',
    eventsHandler(
      storage: storage,
      contentKey: contentKey,
      identityLookup: identityLookup,
    ),
  );
  router.post(
    '/events',
    eventsPushHandler(
      storage: storage,
      contentKey: contentKey,
      clock: clock,
    ),
  );
  router.get(
    '/media/<hash>',
    mediaHandler(
      storage: storage,
      appSupportDir: appSupportDir,
    ),
  );
  router.post(
    '/follow-request',
    followRequestHandler(
      storage: storage,
      clock: clock,
    ),
  );
  router.post('/follow-accept', (Request request) async {
    final followService = followServiceLookup();
    if (followService == null) {
      return Response.notFound('follow service unavailable');
    }
    return followAcceptHandler(followService: followService)(request);
  });
  return router;
}

Router _buildRelayRouter({
  required RelayDao relayDao,
  required PairingService pairingService,
  required RelayMediaStore mediaStore,
  required CryptoService crypto,
  required Clock clock,
  required String Function() relayOnion,
}) {
  final router = Router();

  // Public reads — no auth, same wire shape as social mode so existing
  // Follower-side sync code (PeerReachabilityMonitor, SyncEngine,
  // RemoteMediaFetcher) consumes Relay responses unchanged.
  router.get(
    '/status',
    relayStatusHandler(dao: relayDao, mediaStore: mediaStore),
  );
  router.get(
    '/manifest',
    relayManifestHandler(dao: relayDao),
  );
  router.get(
    '/events',
    relayEventsHandler(dao: relayDao),
  );
  router.get(
    '/media/<hash>',
    relayMediaHandler(mediaStore: mediaStore),
  );

  router.post(
    '/pair',
    relayPairHandler(
      pairingService: pairingService,
      relayOnion: relayOnion,
    ),
  );

  // Owner-only writes. The middleware reads & verifies the body before
  // the inner handler sees it, then re-injects the body for parsing.
  final ownerAuth = ownerSignatureMiddleware(
    crypto: crypto,
    getOwnerPubkey: () async {
      final row = await relayDao.getPairedOwner();
      return row?.pubkey;
    },
  );

  router.post(
    '/events',
    Pipeline().addMiddleware(ownerAuth).addHandler(
          relayEventsPushHandler(dao: relayDao),
        ),
  );

  router.post(
    '/media/<hash>',
    Pipeline().addMiddleware(ownerAuth).addHandler(
          relayMediaPushHandler(
            mediaStore: mediaStore,
            clock: clock,
          ),
        ),
  );

  return router;
}
