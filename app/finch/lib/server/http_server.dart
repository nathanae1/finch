import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../services/clock.dart';
import '../services/content_key_service.dart';
import '../services/follow_service.dart';
import '../services/storage_service.dart';
import '../services/types.dart';
import 'handlers/events_handler.dart';
import 'handlers/follow_accept_handler.dart';
import 'handlers/follow_request_handler.dart';
import 'handlers/manifest_handler.dart';
import 'handlers/media_handler.dart';
import 'handlers/status_handler.dart';
import 'middleware/error_handler.dart';
import 'middleware/rate_limit.dart';

/// Embedded shelf HTTP server that exposes the device owner's content to
/// peers. Binds to a random ephemeral port (49152–65535) and exposes that
/// port via [port] so mDNS (Plan 09) and Tor (Plan 11) can advertise it.
class FinchHttpServer {
  FinchHttpServer({
    required StorageService storage,
    required ContentKeyService contentKey,
    required Future<Identity?> Function() identityLookup,
    required Directory appSupportDir,
    required Clock clock,
    FollowService? followService,
    int maxBindAttempts = 5,
    int rateLimitPerMinute = 120,
    int maxBodyBytes = 1024 * 1024,
    Random? random,
  })  : _storage = storage,
        _contentKey = contentKey,
        _identityLookup = identityLookup,
        _appSupportDir = appSupportDir,
        _clock = clock,
        _followService = followService,
        _maxBindAttempts = maxBindAttempts,
        _rateLimitPerMinute = rateLimitPerMinute,
        _maxBodyBytes = maxBodyBytes,
        _random = random ?? Random.secure();

  static const int _portMin = 49152;
  static const int _portMax = 65535;

  final StorageService _storage;
  final ContentKeyService _contentKey;
  final Future<Identity?> Function() _identityLookup;
  final Directory _appSupportDir;
  final Clock _clock;
  final FollowService? _followService;
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

  Router _buildRouter() {
    final router = Router();
    router.get(
      '/status',
      statusHandler(
        storage: _storage,
        identityLookup: _identityLookup,
      ),
    );
    router.get(
      '/manifest',
      manifestHandler(
        storage: _storage,
        identityLookup: _identityLookup,
      ),
    );
    router.get(
      '/events',
      eventsHandler(
        storage: _storage,
        contentKey: _contentKey,
        identityLookup: _identityLookup,
      ),
    );
    router.get(
      '/media/<hash>',
      mediaHandler(
        storage: _storage,
        appSupportDir: _appSupportDir,
      ),
    );
    router.post(
      '/follow-request',
      followRequestHandler(
        storage: _storage,
        clock: _clock,
      ),
    );
    final followService = _followService;
    if (followService != null) {
      router.post(
        '/follow-accept',
        followAcceptHandler(followService: followService),
      );
    }
    return router;
  }
}
