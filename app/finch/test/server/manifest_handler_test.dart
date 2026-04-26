import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:finch/server/handlers/manifest_handler.dart';
import 'package:finch/services/mocks/mock_clock.dart';
import 'package:finch/services/storage/database.dart';
import 'package:finch/services/storage/drift_storage_service.dart';
import 'package:finch/services/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftStorageService storage;
  late Identity identity;

  setUp(() async {
    db = AppDatabase.memory();
    storage = DriftStorageService(db, MockClock());
    identity = buildIdentity();
    await storage.saveIdentity(identity);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Response> get(String path, {int pageLimit = 1000}) async {
    final handler = manifestHandler(
      storage: storage,
      identityLookup: () async => identity,
      pageLimit: pageLimit,
    );
    return handler(Request('GET', Uri.parse('http://localhost$path')));
  }

  Map<dynamic, dynamic> decodeBody(Uint8List bytes) =>
      cbor.decode(bytes) as Map<dynamic, dynamic>;

  test('empty DB → empty events, has_older false', () async {
    final res = await get('/manifest?since=0');
    expect(res.statusCode, 200);
    expect(res.headers['content-type'], 'application/cbor');
    final body = decodeBody(
      Uint8List.fromList(await res.read().expand((c) => c).toList()),
    );
    expect(body['pubkey'], identity.pubkey);
    expect(body['events'], isEmpty);
    expect(body['has_older'], isFalse);
  });

  test('since/until filters', () async {
    for (var i = 0; i < 5; i++) {
      await storage.saveEvent(
        buildEvent(id: 'e$i', pubkey: identity.pubkey, createdAt: 100 + i),
      );
    }
    final res = await get('/manifest?since=102&until=103');
    final body = decodeBody(
      Uint8List.fromList(await res.read().expand((c) => c).toList()),
    );
    final events = body['events'] as List<dynamic>;
    expect(events, hasLength(2));
    final ids = events.map((e) => (e as Map)['id']).toSet();
    expect(ids, {'e2', 'e3'});
  });

  test('invalid since → 400', () async {
    final res = await get('/manifest?since=abc');
    expect(res.statusCode, 400);
  });

  test('paging beyond pageLimit sets has_older true', () async {
    for (var i = 0; i < 7; i++) {
      await storage.saveEvent(
        buildEvent(id: 'e$i', pubkey: identity.pubkey, createdAt: 100 + i),
      );
    }
    final res = await get('/manifest?since=0', pageLimit: 5);
    final body = decodeBody(
      Uint8List.fromList(await res.read().expand((c) => c).toList()),
    );
    expect((body['events'] as List<dynamic>), hasLength(5));
    expect(body['has_older'], isTrue);
  });

  test('returns 503 when identity is null', () async {
    final handler = manifestHandler(
      storage: storage,
      identityLookup: () async => null,
    );
    final res =
        await handler(Request('GET', Uri.parse('http://localhost/manifest')));
    expect(res.statusCode, 503);
  });
}
