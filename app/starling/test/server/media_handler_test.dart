import 'dart:io';
import 'dart:typed_data';

import 'package:starling/server/http_server.dart';
import 'package:starling/services/media/encrypted_media_paths.dart';
import 'package:starling/services/mocks/mock_clock.dart';
import 'package:starling/services/mocks/mock_content_key_service.dart';
import 'package:starling/services/mocks/mock_crypto_service.dart';
import 'package:starling/services/storage/database.dart';
import 'package:starling/services/storage/drift_storage_service.dart';
import 'package:starling/services/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';
import 'http_test_utils.dart';

/// `mediaHandler` is wired into the router with a path parameter
/// (`/media/<hash>`), so we exercise it through a real bound server to
/// keep the path-extraction code in scope.
void main() {
  late AppDatabase db;
  late DriftStorageService storage;
  late Directory tmpDir;
  late StarlingHttpServer server;
  late Identity identity;

  setUp(() async {
    db = AppDatabase.memory();
    final clock = MockClock();
    storage = DriftStorageService(db, clock);
    tmpDir = await Directory.systemTemp.createTemp('starling-media-test-');
    identity = buildIdentity();
    await storage.saveIdentity(identity);
    server = StarlingHttpServer.social(
      storage: storage,
      contentKey: MockContentKeyService(),
      identityLookup: () async => identity,
      appSupportDir: tmpDir,
      clock: clock,
      crypto: MockCryptoService(),
      signalingInboundHandler: (_) {},
    );
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    await db.close();
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
  });

  Future<String> seedMedia(Uint8List bytes, {String? hexHash}) async {
    final hash = hexHash ?? List.generate(64, (_) => 'a').join();
    final file = await resolveMediaFile(tmpDir, hash);
    await file.writeAsBytes(bytes);
    await storage.saveMedia(
      CachedMedia(
        hash: hash,
        path: file.path,
        size: bytes.length,
        lastAccessed: 100,
      ),
    );
    return hash;
  }

  test('returns the encrypted bytes with content-length', () async {
    final bytes = Uint8List.fromList(List.generate(64, (i) => i));
    final hash = await seedMedia(bytes);
    final res = await fetchHttp(server.port!, '/media/$hash');
    expect(res.statusCode, 200);
    expect(res.headers['content-type']?.first, 'application/octet-stream');
    expect(res.headers['content-length']?.first, bytes.length.toString());
    expect(res.body, bytes);
  });

  test('404 when hash not in DB', () async {
    final hash = List.generate(64, (_) => 'b').join();
    final res = await fetchHttp(server.port!, '/media/$hash');
    expect(res.statusCode, 404);
  });

  test('404 when DB has the row but the file is missing', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final hash = await seedMedia(bytes);
    final file = await resolveMediaFile(tmpDir, hash);
    await file.delete();
    final res = await fetchHttp(server.port!, '/media/$hash');
    expect(res.statusCode, 404);
  });

  test('400 on non-hex hash', () async {
    final res = await fetchHttp(server.port!, '/media/${'Z' * 64}');
    expect(res.statusCode, 400);
  });

  test('400 on wrong-length hash', () async {
    final res = await fetchHttp(server.port!, '/media/${'a' * 10}');
    expect(res.statusCode, 400);
  });
}
