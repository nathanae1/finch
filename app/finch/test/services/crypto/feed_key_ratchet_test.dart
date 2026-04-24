import 'dart:typed_data';

import 'package:finch/services/crypto/feed_key_ratchet.dart';
import 'package:finch/services/crypto/sodium_crypto_service.dart';
import 'package:finch/services/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CryptoService crypto;

  setUpAll(() async {
    crypto = await SodiumCryptoService.init();
  });

  group('ratchetFeedKey', () {
    test('produces 32 bytes', () {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      expect(ratchetFeedKey(key, crypto).length, 32);
    });

    test('is deterministic', () {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      expect(ratchetFeedKey(key, crypto), ratchetFeedKey(key, crypto));
    });

    test('produces a different key than the input', () {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      expect(ratchetFeedKey(key, crypto), isNot(key));
    });

    test('successive ratchets diverge', () {
      final k0 = Uint8List.fromList(List.filled(32, 0x42));
      final k1 = ratchetFeedKey(k0, crypto);
      final k2 = ratchetFeedKey(k1, crypto);
      expect(k0, isNot(k1));
      expect(k1, isNot(k2));
      expect(k0, isNot(k2));
    });

    test('zero input produces non-zero output', () {
      final next = ratchetFeedKey(Uint8List(32), crypto);
      expect(next.any((b) => b != 0), isTrue);
    });

    test('backward derivation is infeasible (smoke check)', () {
      // We cannot actually prove preimage-resistance here, but we can verify
      // that the next key is not trivially related to the input.
      final k = Uint8List.fromList(List.generate(32, (i) => i * 7));
      final next = ratchetFeedKey(k, crypto);
      // No linear relationship like XOR-identity or simple rotation.
      expect(next, isNot(k));
      for (var shift = 1; shift < 32; shift++) {
        final rotated = Uint8List(32);
        for (var i = 0; i < 32; i++) {
          rotated[i] = k[(i + shift) % 32];
        }
        expect(next, isNot(rotated));
      }
    });
  });

  group('deriveEpochKey', () {
    test('delta 0 returns base key unchanged', () {
      final base = Uint8List.fromList(List.generate(32, (i) => i * 3));
      expect(deriveEpochKey(base, 0, crypto), base);
    });

    test('delta 1 matches a single ratchet', () {
      final base = Uint8List.fromList(List.generate(32, (i) => i * 3));
      expect(deriveEpochKey(base, 1, crypto), ratchetFeedKey(base, crypto));
    });

    test('delta N equals N manual applications', () {
      final base = Uint8List.fromList(List.generate(32, (i) => i));
      var manual = base;
      for (var i = 0; i < 5; i++) {
        manual = ratchetFeedKey(manual, crypto);
      }
      expect(deriveEpochKey(base, 5, crypto), manual);
    });

    test('negative delta throws', () {
      expect(
        () => deriveEpochKey(Uint8List(32), -1, crypto),
        throwsArgumentError,
      );
    });
  });
}
