import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:finch/models/connection_card.dart';
import 'package:finch/services/crypto/crockford_base32.dart';
import 'package:finch/services/crypto/sodium_crypto_service.dart';
import 'package:finch/services/crypto_service.dart';
import 'package:finch/services/follow_service.dart';
import 'package:finch/services/mocks/mock_clock.dart';
import 'package:finch/services/mocks/mock_storage_service.dart';
import 'package:finch/services/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CryptoService crypto;

  setUpAll(() async {
    crypto = await SodiumCryptoService.init();
  });

  group('FollowService handshake', () {
    late _Peer alice;
    late _Peer bob;
    late _PairTransport transport;

    setUp(() async {
      alice = await _Peer.build(crypto, label: 'alice');
      bob = await _Peer.build(crypto, label: 'bob');
      transport = _PairTransport({
        alice.baseUrl: alice,
        bob.baseUrl: bob,
      });
      alice.attachTransport(transport);
      bob.attachTransport(transport);
    });

    tearDown(() async {
      await alice.storage.dispose();
      await bob.storage.dispose();
    });

    test('alice → bob: alice ends up with bob\'s feed key + connection card',
        () async {
      await alice.service.sendFollowRequest(bob.connectionCard());
      // Bob now has an inbound row.
      expect(await bob.storage.getInboundRequests(), hasLength(1));

      final delivery =
          await bob.service.acceptFollowRequest(alice.identity.pubkey);
      expect(delivery, AcceptDelivery.delivered);

      final follow = await alice.storage.getFollow(bob.identity.pubkey);
      expect(follow, isNotNull);
      expect(follow!.feedKey, equals(bob.identity.feedKey));
      expect(follow.feedKeyEpoch, equals(bob.identity.feedKeyEpoch));

      // Inbound row marked accepted (so it disappears from pending).
      expect(await bob.storage.getInboundRequests(), isEmpty);
      // Outbound row consumed.
      expect(await alice.storage.getOutboundRequests(), isEmpty);
      // No leftover queue entries.
      expect(await alice.storage.dequeue(bob.identity.pubkey), isEmpty);
    });

    test('reject deletes inbound row, no follows write', () async {
      await alice.service.sendFollowRequest(bob.connectionCard());
      expect(await bob.storage.getInboundRequests(), hasLength(1));

      await bob.service.rejectFollowRequest(alice.identity.pubkey);

      expect(await bob.storage.getInboundRequests(), isEmpty);
      expect(await bob.storage.getFollow(alice.identity.pubkey), isNull);
    });

    test('accept queues retry when transport fails', () async {
      await alice.service.sendFollowRequest(bob.connectionCard());

      // Make the transport fail when bob tries to deliver to alice.
      transport.failNextAcceptTo = alice.baseUrl;
      final delivery =
          await bob.service.acceptFollowRequest(alice.identity.pubkey);
      expect(delivery, AcceptDelivery.queued);

      // Inbound row stays around in pending-send state.
      final pending =
          await bob.storage.getInboundRequestsByStatus('pending-send');
      expect(pending, hasLength(1));
      // A queue entry exists for alice.
      final queued = await bob.storage.dequeue(alice.identity.pubkey);
      expect(queued, hasLength(1));

      // On the next pump, transport works → accept lands.
      transport.failNextAcceptTo = null;
      await bob.service.retryQueuedAccepts();
      expect(await bob.storage.dequeue(alice.identity.pubkey), isEmpty);
      expect(
        await bob.storage.getInboundRequestsByStatus('pending-send'),
        isEmpty,
      );
      final follow = await alice.storage.getFollow(bob.identity.pubkey);
      expect(follow, isNotNull);
      expect(follow!.feedKey, equals(bob.identity.feedKey));
    });

    test('retry pump marks send-failed after maxRetries', () async {
      await alice.service.sendFollowRequest(bob.connectionCard());
      transport.failNextAcceptTo = alice.baseUrl;
      transport.failPersistently = true;
      final delivery =
          await bob.service.acceptFollowRequest(alice.identity.pubkey);
      expect(delivery, AcceptDelivery.queued);

      // Pump enough times to exhaust the retry budget.
      for (var i = 0; i < 10; i++) {
        await bob.service.retryQueuedAccepts(maxRetries: 3);
      }

      final failed =
          await bob.storage.getInboundRequestsByStatus('send-failed');
      expect(failed, hasLength(1));
      expect(await bob.storage.dequeue(alice.identity.pubkey), isEmpty);
    });
  });
}

class _Peer {
  _Peer._({
    required this.label,
    required this.crypto,
    required this.identity,
    required this.secretKey,
    required this.storage,
  })  : clock = MockClock(2_000_000),
        baseUrl = 'http://$label.local:8080';

  final String label;
  final CryptoService crypto;
  final Identity identity;
  final Uint8List secretKey;
  final MockStorageService storage;
  final MockClock clock;
  final String baseUrl;

  late FollowService service;

  static Future<_Peer> build(CryptoService crypto, {required String label}) async {
    final kp = await crypto.generateKeyPair();
    final identity = Identity(
      pubkey: crockfordBase32Encode(kp.publicKey),
      feedKey: crypto.randomBytes(32),
      feedKeyEpoch: label == 'bob' ? 7 : 3,
      createdAt: 1_000_000,
    );
    final storage = MockStorageService();
    await storage.saveIdentity(identity);
    return _Peer._(
      label: label,
      crypto: crypto,
      identity: identity,
      secretKey: kp.secretKey,
      storage: storage,
    );
  }

  ConnectionCard connectionCard() => ConnectionCard(
        pubkey: identity.pubkey,
        endpoints: [Endpoint(type: 'direct', address: _hostFromUrl(baseUrl))],
      );

  void attachTransport(_PairTransport transport) {
    service = FollowService(
      crypto: crypto,
      storage: storage,
      clock: clock,
      transport: transport,
      identityLookup: storage.getIdentity,
      ownSecretKeyLookup: () async => secretKey,
      ownEndpointsLookup: () async => connectionCard().endpoints,
    );
  }
}

String _hostFromUrl(String url) {
  final uri = Uri.parse(url);
  return '${uri.host}:${uri.port}';
}

/// Hand-delivers /follow-request and /follow-accept POSTs straight into the
/// peer's storage / FollowService, mimicking the http handlers.
class _PairTransport implements HandshakeTransport {
  _PairTransport(this._byBaseUrl);

  final Map<String, _Peer> _byBaseUrl;
  String? failNextAcceptTo;
  bool failPersistently = false;

  @override
  Future<int> postFollowRequest(String baseUrl, Uint8List body) async {
    final peer = _resolve(baseUrl);
    final outer = cbor.decode(body) as Map<dynamic, dynamic>;
    final timestamp = outer['timestamp'] as int;
    await peer.storage.saveInboundRequest(
      FollowRequest(
        pubkey: outer['requester_pubkey'] as String,
        payload: body,
        createdAt: peer.clock.nowUnixSeconds(),
        requestTimestamp: timestamp,
      ),
    );
    return 202;
  }

  @override
  Future<int> postFollowAccept(String baseUrl, Uint8List body) async {
    if (failNextAcceptTo == baseUrl) {
      if (!failPersistently) failNextAcceptTo = null;
      throw http.ClientException('simulated network failure', Uri.parse(baseUrl));
    }
    final peer = _resolve(baseUrl);
    final outer = cbor.decode(body) as Map<dynamic, dynamic>;
    await peer.service.ingestFollowAccept(
      ownerPubkey: outer['owner_pubkey'] as String,
      encryptedFeedKey: _bytes(outer['encrypted_feed_key']),
      nonce: _bytes(outer['nonce']),
      epoch: outer['epoch'] as int,
      timestamp: outer['timestamp'] as int,
    );
    return 202;
  }

  _Peer _resolve(String baseUrl) {
    final peer = _byBaseUrl[baseUrl];
    if (peer == null) {
      throw http.ClientException('no peer at $baseUrl', Uri.parse(baseUrl));
    }
    return peer;
  }

  Uint8List _bytes(dynamic v) {
    if (v is Uint8List) return v;
    if (v is List<int>) return Uint8List.fromList(v);
    throw StateError('expected bytes, got ${v.runtimeType}');
  }
}
