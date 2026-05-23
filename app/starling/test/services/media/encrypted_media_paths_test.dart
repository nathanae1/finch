import 'dart:io';

import 'package:starling/services/media/encrypted_media_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mediaRelativePath', () {
    test('shards by the first two and four hex chars', () {
      final hash = 'a' * 64;
      expect(mediaRelativePath(hash), equals('media/aa/aaaa/$hash'));
    });

    test('distinct hashes with the same prefix share shard dirs', () {
      final h1 = 'deadbeef${'0' * 56}';
      final h2 = 'deadbeef${'1' * 56}';
      final p1 = mediaRelativePath(h1);
      final p2 = mediaRelativePath(h2);
      expect(p1, startsWith('media/de/dead/'));
      expect(p2, startsWith('media/de/dead/'));
      expect(p1, isNot(equals(p2)));
    });
  });

  group('resolveMediaFile', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('starling-paths-test-');
    });

    tearDown(() async {
      if (tmp.existsSync()) await tmp.delete(recursive: true);
    });

    test('creates parent shard directories', () async {
      final hash = '0123456789abcdef' * 4;
      final file = await resolveMediaFile(tmp, hash);
      expect(file.parent.existsSync(), isTrue);
      expect(file.path, endsWith('media/01/0123/$hash'));
      // File itself is NOT created
      expect(file.existsSync(), isFalse);
    });

    test('is idempotent across multiple calls', () async {
      final hash = 'f' * 64;
      final a = await resolveMediaFile(tmp, hash);
      final b = await resolveMediaFile(tmp, hash);
      expect(a.path, equals(b.path));
    });
  });
}
