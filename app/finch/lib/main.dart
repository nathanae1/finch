import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'providers/deep_link_provider.dart';
import 'providers/discovery_provider.dart';
import 'providers/follow_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/server_provider.dart';
import 'providers/service_providers.dart';
import 'router.dart';
import 'screens/friends/confirm_request_sheet.dart';
import 'services/clock.dart';
import 'services/content_key_service.dart';
import 'services/crypto/key_cache.dart';
import 'services/crypto/pairwise_content_key_service.dart';
import 'services/crypto/sodium_crypto_service.dart';
import 'services/follow_retry_pump.dart';
import 'services/mdns_service.dart';
import 'services/storage/database.dart';
import 'services/storage/drift_storage_service.dart';
import 'services/tor/arti_tor_service.dart';
import 'theme/finch_theme.dart';
import 'utils/connection_card_parser.dart';
import 'widgets/sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await _initStorageService();
  final crypto = await SodiumCryptoService.init();

  final mdns = MethodChannelMdnsService();
  final torService = _shouldUseRealTor() ? ArtiTorService() : null;

  final overrides = <Override>[
    storageServiceProvider.overrideWithValue(storage),
    cryptoServiceProvider.overrideWithValue(crypto),
    mdnsServiceProvider.overrideWithValue(mdns),
    if (torService != null) torServiceProvider.overrideWithValue(torService),
  ];

  // If identity already exists at launch, hydrate the feed-key cache and
  // wire the real PairwiseContentKeyService. Without identity (pre-onboarding
  // or restore-in-progress) we stay on MockContentKeyService — nothing in
  // Plan 04's scope actually invokes it, and the first launch after
  // onboarding will wire it up.
  final identity = await storage.getIdentity();
  if (identity != null) {
    final secretKey = await _loadSecretKey();
    if (secretKey != null) {
      final follows = await storage.getFollows();
      final cache = FeedKeyCache()
        ..put(identity.pubkey, identity.feedKey, identity.feedKeyEpoch);
      for (final f in follows) {
        cache.put(f.pubkey, f.feedKey, f.feedKeyEpoch);
      }
      final contentKey = PairwiseContentKeyService(
        crypto: crypto,
        cache: cache,
        ownPubkey: identity.pubkey,
        ownSecretKey: secretKey,
      );
      overrides.add(
        contentKeyServiceProvider
            .overrideWithValue(contentKey as ContentKeyService),
      );
    }
  }

  runApp(ProviderScope(overrides: overrides, child: const FinchApp()));
}

Future<DriftStorageService> _initStorageService() async {
  const storage = FlutterSecureStorage();
  const keyName = 'finch_db_key';

  var dbKey = await storage.read(key: keyName);
  if (dbKey == null) {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    dbKey = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await storage.write(key: keyName, value: dbKey);
  }

  final db = AppDatabase.encrypted(dbKey);
  return DriftStorageService(db, const SystemClock());
}

Future<Uint8List?> _loadSecretKey() async {
  const secure = FlutterSecureStorage();
  final encoded = await secure.read(key: kSecretKeyStorageName);
  if (encoded == null) return null;
  return Uint8List.fromList(base64Decode(encoded));
}

/// Real Tor only on iOS/Android — those are the only platforms the
/// `arti_bridge` Rust crate is cross-compiled for in Plan 11. Desktop
/// `flutter test` and `flutter run` on macOS keep the [MockTorService]
/// default from `service_providers.dart`.
bool _shouldUseRealTor() {
  if (kIsWeb) return false;
  return Platform.isIOS || Platform.isAndroid;
}

class FinchApp extends ConsumerStatefulWidget {
  const FinchApp({super.key});

  @override
  ConsumerState<FinchApp> createState() => _FinchAppState();
}

class _FinchAppState extends ConsumerState<FinchApp>
    with WidgetsBindingObserver {
  FollowRetryPump? _retryPump;
  ProviderSubscription<AsyncValue<ParsedInvite>>? _deepLinkSub;
  ProviderSubscription<AsyncValue<int?>>? _torPortSub;
  String? _onionAddress;
  // Memoized init future: any caller (initState, lifecycle, port listener)
  // gets back the same in-flight Future and races resolve cleanly.
  Future<void>? _torInitFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Eagerly start the embedded HTTP server. The provider waits for
    // identity to be loaded before it actually binds a port.
    ref.read(httpServerControllerProvider);
    // Eagerly bring up mDNS discovery; the controller no-ops until both
    // identity and the server port are ready.
    ref.read(discoveryControllerProvider);
    _retryPump = FollowRetryPump(followService: ref.read(followServiceProvider))
      ..start();
    _deepLinkSub = ref.listenManual<AsyncValue<ParsedInvite>>(
      deepLinkInvitesProvider,
      (_, next) {
        final invite = next.valueOrNull;
        if (invite is ValidInvite) {
          final ctx = ref.read(routerProvider).routerDelegate.navigatorKey
              .currentContext;
          if (ctx != null) {
            showFinchSheet(
              context: ctx,
              builder: (_) => ConfirmRequestSheet(card: invite.card),
            );
          }
        }
      },
    );
    // Plan 11a: bring up Tor in parallel with everything else. Bootstrap
    // can take 10–30s; we deliberately don't await it so LAN sync stays
    // available during startup. Failures are logged but never thrown.
    unawaited(_ensureTorInit());
    // Re-create the onion service whenever the HTTP server's bound port
    // changes (initial start, after a lifecycle restart). Arti reuses the
    // persisted keypair so the .onion address is stable across rebinds.
    _torPortSub = ref.listenManual<AsyncValue<int?>>(
      httpServerControllerProvider,
      (_, next) {
        final port = next.valueOrNull;
        if (port != null) {
          unawaited(_publishOnion(port));
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_retryPump?.stop());
    _deepLinkSub?.close();
    _torPortSub?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(httpServerControllerProvider.notifier);
    final tor = ref.read(torServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(notifier.restart());
        unawaited(_ensureTorInit());
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(notifier.stop());
        _onionAddress = null;
        _torInitFuture = null;
        unawaited(tor.shutdown());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _ensureTorInit() {
    return _torInitFuture ??= () async {
      try {
        final tor = ref.read(torServiceProvider);
        final supportDir = await getApplicationSupportDirectory();
        final torDir = Directory('${supportDir.path}/tor');
        await torDir.create(recursive: true);
        await tor.init(torDir.path);
        developer.log('tor.init complete', name: 'finch.tor');
      } catch (e, st) {
        developer.log(
          'tor.init failed: $e',
          name: 'finch.tor',
          stackTrace: st,
        );
        // Drop the cached future on failure so a future port event can
        // retry from a clean slate.
        _torInitFuture = null;
        rethrow;
      }
    }();
  }

  Future<void> _publishOnion(int port) async {
    if (_onionAddress != null) return;
    try {
      await _ensureTorInit();
      final tor = ref.read(torServiceProvider);
      final addr = await tor.createOnionService(port);
      _onionAddress = addr;
      developer.log('onion=$addr port=$port', name: 'finch.tor');
    } catch (e, st) {
      developer.log(
        'createOnionService failed: $e',
        name: 'finch.tor',
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Finch',
      theme: buildFinchMaterialTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final routerProvider = Provider((ref) => buildRouter(ref));
