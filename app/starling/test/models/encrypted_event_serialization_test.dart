import 'dart:typed_data';

import 'package:starling/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncryptedEvent CBOR serialization', () {
    test('round-trips through bytes', () {
      final event = EncryptedEvent(
        pubkey: 'test-pubkey',
        createdAt: 1711324800,
        epoch: 0,
        msgSeq: 0,
        nonce: Uint8List.fromList(List.filled(24, 0xAB)),
        payload: Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      final decoded = EncryptedEvent.fromBytes(event.toBytes());
      expect(decoded, equals(event));
    });

    test('preserves large payload', () {
      final largePayload = Uint8List.fromList(List.filled(10240, 0x42));
      final event = EncryptedEvent(
        pubkey: 'test-pubkey',
        createdAt: 1711324800,
        epoch: 0,
        msgSeq: 0,
        nonce: Uint8List.fromList(List.filled(24, 0x01)),
        payload: largePayload,
      );
      final decoded = EncryptedEvent.fromBytes(event.toBytes());
      expect(decoded.payload.length, equals(10240));
      expect(decoded, equals(event));
    });

    test('equality works correctly', () {
      final nonce = Uint8List.fromList(List.filled(24, 0x01));
      final payload = Uint8List.fromList([10, 20, 30]);
      final a = EncryptedEvent(
        pubkey: 'pk',
        createdAt: 100,
        epoch: 0,
        msgSeq: 0,
        nonce: nonce,
        payload: payload,
      );
      final b = EncryptedEvent(
        pubkey: 'pk',
        createdAt: 100,
        epoch: 0,
        msgSeq: 0,
        nonce: Uint8List.fromList(List.filled(24, 0x01)),
        payload: Uint8List.fromList([10, 20, 30]),
      );
      expect(a, equals(b));
    });
  });
}
