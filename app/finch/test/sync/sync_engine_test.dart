import 'dart:typed_data';

import 'package:finch/models/models.dart';
import 'package:finch/services/content_key_service.dart';
import 'package:finch/services/crypto/crockford_base32.dart';
import 'package:finch/services/crypto/key_cache.dart';
import 'package:finch/services/crypto/pairwise_content_key_service.dart';
import 'package:finch/services/crypto/sodium_crypto_service.dart';
import 'package:finch/services/crypto_service.dart';
import 'package:finch/services/mocks/mock_clock.dart';
import 'package:finch/services/mocks/mock_mdns_service.dart';
import 'package:finch/services/storage/database.dart';
import 'package:finch/services/storage/drift_storage_service.dart';
import 'package:finch/services/types.dart';
import 'package:finch/sync/peer_connection_factory.dart';
import 'package:finch/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CryptoService crypto;

  setUpAll(() async {
    crypto = await SodiumCryptoService.init();
  });

  group('SyncEngine', () {
    late _Peer alice;
    late _Peer bob;
    late _RouteableTransport transport;
    late MockMdnsService bobMdns;
    late SyncEngine bobEngine;

    setUp(() async {
      alice = await _Peer.build(crypto, label: 'alice');
      bob = await _Peer.build(crypto, label: 'bob');

      transport = _RouteableTransport({
        alice.identity.pubkey: alice,
      });
      bobMdns = MockMdnsService();
      // Bob's mDNS sees Alice as a reachable peer.
      bobMdns.setPeer(LanPeer(
        pubkey: alice.identity.pubkey,
        host: '10.0.0.1',
        port: 49000,
      ));

      // Bob has an active follow on Alice using Alice's feed key.
      await bob.storage.saveFollow(Follow(
        pubkey: alice.identity.pubkey,
        connectionCard: '',
        feedKey: alice.identity.feedKey,
        feedKeyEpoch: alice.identity.feedKeyEpoch,
        lastSyncedAt: 0,
      ));

      bobEngine = SyncEngine(
        storage: bob.storage,
        contentKey: bob.contentKey,
        transport: transport,
        peerFactory: PeerConnectionFactory(mdns: bobMdns),
        clock: bob.clock,
      );
    });

    tearDown(() async {
      await alice.dispose();
      await bob.dispose();
      await bobMdns.dispose();
    });

    test('pulls all of alice\'s events and decrypts them', () async {
      // Alice publishes 3 posts.
      for (var i = 0; i < 3; i++) {
        alice.clock.advance(60);
        await alice.publishPost('hello $i');
      }

      final report = await bobEngine.syncNow();
      expect(report.peers, hasLength(1));
      expect(report.peers.single.status, equals(PeerSyncStatus.synced));
      expect(report.peers.single.eventsFetched, equals(3));

      final stored = await bob.storage
          .getEvents(pubkey: alice.identity.pubkey);
      expect(stored, hasLength(3));
      expect(stored.every((e) => e.kind == EventKind.post), isTrue);

      // last_synced_at advanced.
      final follow = await bob.storage.getFollow(alice.identity.pubkey);
      expect(follow!.lastSyncedAt, greaterThan(0));
    });

    test('re-running syncNow does not duplicate events', () async {
      alice.clock.advance(60);
      await alice.publishPost('once');

      await bobEngine.syncNow();
      final after1 = await bob.storage.getEvents(pubkey: alice.identity.pubkey);
      expect(after1, hasLength(1));

      // Second sync within the same window should diff manifest → empty.
      await bobEngine.syncNow();
      final after2 = await bob.storage.getEvents(pubkey: alice.identity.pubkey);
      expect(after2, hasLength(1));
    });

    test('peer not in mDNS cache → marked unreachable, sync continues',
        () async {
      bobMdns.removePeer(alice.identity.pubkey);
      final report = await bobEngine.syncNow();
      expect(report.peers.single.status, equals(PeerSyncStatus.unreachable));

      final stored =
          await bob.storage.getEvents(pubkey: alice.identity.pubkey);
      expect(stored, isEmpty);
    });

    test('tampered EncryptedEvent payload is skipped, not stored', () async {
      alice.clock.advance(60);
      await alice.publishPost('legit');

      // Inject a tampered encrypted event with the same pubkey but
      // garbage payload, alongside the legit one.
      transport.tamperNextEnvelopeFor = alice.identity.pubkey;

      final report = await bobEngine.syncNow();
      expect(report.peers.single.status, equals(PeerSyncStatus.synced));
      // The legit event went through; the tampered one was rejected.
      expect(report.peers.single.eventsFetched, equals(1));
      expect(report.peers.single.eventsSkipped, equals(1));

      final stored =
          await bob.storage.getEvents(pubkey: alice.identity.pubkey);
      expect(stored, hasLength(1));
    });

    test('unknown EnvelopeItem types are routed to opaque storage', () async {
      alice.clock.advance(60);
      await alice.publishPost('legit');

      // Inject a future "commit" item alongside the event.
      transport.injectExtraItemFor = alice.identity.pubkey;
      transport.injectedItem = EnvelopeItem(
        type: 'commit',
        payload: Uint8List.fromList([1, 2, 3, 4]),
      );

      final report = await bobEngine.syncNow();
      expect(report.peers.single.eventsFetched, equals(1));
      expect(report.peers.single.unknownItemsPreserved, equals(1));

      final unknown =
          await bob.storage.getUnknownEnvelopeItemsByType('commit');
      expect(unknown, hasLength(1));
      expect(unknown.single.sourcePubkey, equals(alice.identity.pubkey));
      expect(unknown.single.payload, equals(Uint8List.fromList([1, 2, 3, 4])));
    });

    test('peer error is contained — reports unreachable, no crash', () async {
      transport.failNextManifestFor = alice.identity.pubkey;
      final report = await bobEngine.syncNow();
      expect(report.peers.single.status, equals(PeerSyncStatus.unreachable));
      expect(report.peers.single.error, isNotNull);
    });
  });
}

class _Peer {
  _Peer._({
    required this.label,
    required this.crypto,
    required this.identity,
    required this.secretKey,
    required this.db,
    required this.storage,
    required this.contentKey,
  }) : clock = MockClock(2_000_000);

  final String label;
  final CryptoService crypto;
  final Identity identity;
  final Uint8List secretKey;
  final AppDatabase db;
  final DriftStorageService storage;
  final ContentKeyService contentKey;
  final MockClock clock;

  static Future<_Peer> build(CryptoService crypto, {required String label}) async {
    final kp = await crypto.generateKeyPair();
    final pubkey = crockfordBase32Encode(kp.publicKey);
    final feedKey = crypto.randomBytes(32);
    final identity = Identity(
      pubkey: pubkey,
      feedKey: feedKey,
      feedKeyEpoch: 0,
      createdAt: 1_000_000,
    );

    final db = AppDatabase.memory();
    final clock = MockClock(2_000_000);
    final storage = DriftStorageService(db, clock);
    await storage.saveIdentity(identity);

    final cache = FeedKeyCache()..put(pubkey, feedKey, 0);
    final contentKey = PairwiseContentKeyService(
      crypto: crypto,
      cache: cache,
      ownPubkey: pubkey,
      ownSecretKey: kp.secretKey,
    );

    return _Peer._(
      label: label,
      crypto: crypto,
      identity: identity,
      secretKey: kp.secretKey,
      db: db,
      storage: storage,
      contentKey: contentKey,
    );
  }

  Future<void> publishPost(String content) async {
    final event = Event(
      version: '2026-03-24',
      id: '',
      pubkey: identity.pubkey,
      createdAt: clock.nowUnixSeconds(),
      kind: EventKind.post,
      content: Uint8List.fromList(content.codeUnits),
      sig: Uint8List(64),
    );
    final result =
        contentKey.signAndEncryptForAudience(event, Audience.broadcast);
    await storage.saveEvent(result.signed);
  }

  Future<void> dispose() async {
    await db.close();
  }
}

/// Routes manifest / envelope / media calls between in-memory peers, with
/// hooks for tests to inject failures or mutate the response.
class _RouteableTransport implements SyncTransport {
  _RouteableTransport(this._peers);
  final Map<String, _Peer> _peers;

  String? failNextManifestFor;
  String? tamperNextEnvelopeFor;
  String? injectExtraItemFor;
  EnvelopeItem? injectedItem;

  @override
  Future<Manifest> fetchManifest(
    PeerConnection peer, {
    int? since,
    int? until,
  }) async {
    if (failNextManifestFor == peer.pubkey) {
      failNextManifestFor = null;
      throw Exception('simulated manifest failure');
    }
    final source = _peers[peer.pubkey]!;
    final events = await source.storage.getEvents(
      pubkey: peer.pubkey,
      since: since,
    );
    return Manifest(
      pubkey: peer.pubkey,
      events: events
          .map((e) => ManifestEntry(id: e.id, createdAt: e.createdAt))
          .toList(),
      hasOlder: false,
    );
  }

  @override
  Future<Envelope> fetchEnvelope(
    PeerConnection peer, {
    int? since,
  }) async {
    final source = _peers[peer.pubkey]!;
    final events = await source.storage.getEvents(
      pubkey: peer.pubkey,
      since: since,
    );
    final items = <EnvelopeItem>[];
    for (final event in events) {
      final encrypted = source.contentKey.encryptEvent(
        event,
        source.identity.feedKey,
        source.identity.feedKeyEpoch,
      );
      items.add(EnvelopeItem(type: 'event', payload: encrypted.toBytes()));
    }

    if (tamperNextEnvelopeFor == peer.pubkey) {
      tamperNextEnvelopeFor = null;
      // Add a tampered "event" item with random bytes that won't decrypt.
      items.add(EnvelopeItem(
        type: 'event',
        payload: EncryptedEvent(
          pubkey: peer.pubkey,
          createdAt: events.isEmpty ? 0 : events.first.createdAt + 1,
          epoch: 0,
          nonce: Uint8List(24),
          payload: Uint8List.fromList(List.filled(64, 0xFF)),
        ).toBytes(),
      ));
    }

    if (injectExtraItemFor == peer.pubkey && injectedItem != null) {
      items.add(injectedItem!);
      injectExtraItemFor = null;
      injectedItem = null;
    }

    return Envelope(version: '2026-03-24', items: items);
  }

  @override
  Future<Uint8List> fetchMedia(PeerConnection peer, String hash) async {
    return Uint8List(0);
  }
}
