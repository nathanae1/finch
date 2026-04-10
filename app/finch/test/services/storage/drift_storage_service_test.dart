import 'dart:typed_data';

import 'package:finch/models/models.dart';
import 'package:finch/services/storage/database.dart';
import 'package:finch/services/storage/drift_storage_service.dart';
import 'package:finch/services/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftStorageService service;

  setUp(() {
    db = AppDatabase.memory();
    service = DriftStorageService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('identity', () {
    test('returns null initially', () async {
      expect(await service.getIdentity(), isNull);
    });

    test('saves and retrieves', () async {
      final identity = Identity(
        pubkey: 'my-pk',
        feedKey: Uint8List.fromList(List.filled(32, 0xAA)),
        recoveryPhrase: 'word1 word2',
        createdAt: 1000,
      );
      await service.saveIdentity(identity);

      final result = await service.getIdentity();
      expect(result, isNotNull);
      expect(result!.pubkey, equals('my-pk'));
      expect(result.recoveryPhrase, equals('word1 word2'));
    });
  });

  group('follows', () {
    Follow makeFollow(String pk) => Follow(
          pubkey: pk,
          displayName: 'User $pk',
          connectionCard: '{"pubkey":"$pk"}',
          feedKey: Uint8List.fromList(List.filled(32, 0xBB)),
        );

    test('CRUD operations', () async {
      await service.saveFollow(makeFollow('f1'));
      await service.saveFollow(makeFollow('f2'));

      expect(await service.getFollows(), hasLength(2));
      expect((await service.getFollow('f1'))!.pubkey, equals('f1'));

      await service.removeFollow('f1');
      expect(await service.getFollows(), hasLength(1));
      expect(await service.getFollow('f1'), isNull);
    });

    test('updateLastSynced', () async {
      await service.saveFollow(makeFollow('f1'));
      await service.updateLastSynced('f1', 5000);

      final follow = await service.getFollow('f1');
      expect(follow!.lastSyncedAt, equals(5000));
    });
  });

  group('events', () {
    Event makeEvent(String id, {String pubkey = 'author', int createdAt = 1000}) =>
        Event(
          version: '2026-03-24',
          id: id,
          pubkey: pubkey,
          createdAt: createdAt,
          kind: EventKind.post,
          content: Uint8List.fromList([72, 101, 108, 108, 111]),
          media: const [
            MediaRef(hash: 'h1', mimeType: 'image/jpeg', size: 1024),
          ],
          sig: Uint8List.fromList(List.filled(64, 0xFF)),
        );

    test('save and get', () async {
      await service.saveEvent(makeEvent('e1'));
      final event = await service.getEvent('e1');
      expect(event, isNotNull);
      expect(event!.id, equals('e1'));
      expect(event.kind, equals(EventKind.post));
      expect(event.media, hasLength(1));
      expect(event.media.first.hash, equals('h1'));
    });

    test('getFeedEvents includes own and followed', () async {
      await service.saveIdentity(Identity(
        pubkey: 'me',
        feedKey: Uint8List(32),
        createdAt: 1,
      ));
      await service.saveFollow(Follow(
        pubkey: 'friend',
        connectionCard: '{}',
        feedKey: Uint8List(32),
      ));

      await service.saveEvent(makeEvent('e1', pubkey: 'me'));
      await service.saveEvent(makeEvent('e2', pubkey: 'friend'));
      await service.saveEvent(makeEvent('e3', pubkey: 'stranger'));

      final feed = await service.getFeedEvents();
      expect(feed, hasLength(2));
      expect(feed.map((e) => e.pubkey).toSet(), equals({'me', 'friend'}));
    });

    test('delete', () async {
      await service.saveEvent(makeEvent('e1'));
      await service.deleteEvent('e1');
      expect(await service.getEvent('e1'), isNull);
    });
  });

  group('media cache', () {
    test('CRUD and size', () async {
      const media = CachedMedia(
        hash: 'm1',
        path: '/media/m1',
        size: 1024,
        lastAccessed: 1000,
      );
      await service.saveMedia(media);
      expect((await service.getMedia('m1'))!.hash, equals('m1'));
      expect(await service.getMediaCacheSize(), equals(1024));

      await service.deleteMedia('m1');
      expect(await service.getMedia('m1'), isNull);
    });
  });

  group('follow requests', () {
    test('inbound request lifecycle', () async {
      await service.saveInboundRequest(FollowRequest(
        pubkey: 'req-1',
        payload: Uint8List.fromList([1, 2, 3]),
        createdAt: 1000,
      ));

      expect(await service.getInboundRequests(), hasLength(1));

      await service.updateInboundRequestStatus('req-1', 'accepted');
      expect(await service.getInboundRequests(), isEmpty);
    });

    test('outbound request lifecycle', () async {
      await service.saveOutboundRequest(FollowRequest(
        pubkey: 'target-1',
        payload: Uint8List.fromList(
          '{"pubkey":"target-1"}'.codeUnits,
        ),
        createdAt: 2000,
      ));

      final outbound = await service.getOutboundRequests();
      expect(outbound, hasLength(1));
      expect(outbound.first.pubkey, equals('target-1'));
    });
  });

  group('outbound queue', () {
    test('enqueue, dequeue, remove', () async {
      await service.enqueue('target-1', Uint8List.fromList([10, 20]));

      final items = await service.dequeue('target-1');
      expect(items, hasLength(1));
      expect(items.first.retryCount, equals(0));

      await service.incrementRetry(items.first.id);
      final updated = await service.dequeue('target-1');
      expect(updated.first.retryCount, equals(1));

      await service.removeFromQueue(items.first.id);
      expect(await service.dequeue('target-1'), isEmpty);
    });
  });
}
