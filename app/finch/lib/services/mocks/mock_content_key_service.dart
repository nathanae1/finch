import 'dart:typed_data';

import 'package:cbor/simple.dart';

import '../../models/models.dart';
import '../content_key_service.dart';
import '../crypto/crockford_base32.dart';

/// In-memory mock ContentKeyService for testing without native FFI.
/// Uses deterministic values — no real cryptography.
class MockContentKeyService implements ContentKeyService {
  final Uint8List _mockFeedKey = Uint8List.fromList(List.filled(32, 0xAA));

  @override
  Future<Uint8List> generateFeedKey() async =>
      Uint8List.fromList(List.filled(32, 0xAA));

  @override
  Uint8List advanceEpoch(Uint8List currentKey) {
    // Deterministic mock: XOR with 0xFF to produce a different key.
    final next = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      next[i] = currentKey[i] ^ 0xFF;
    }
    return next;
  }

  @override
  EncryptedEvent encryptEvent(Event event, Uint8List epochKey, int epoch) {
    // No real encryption: CBOR-encode the event directly as the payload.
    final payload = Uint8List.fromList(cbor.encode(event.toMap()));
    return EncryptedEvent(
      pubkey: event.pubkey,
      createdAt: event.createdAt,
      epoch: epoch,
      nonce: Uint8List(24), // zero nonce
      payload: payload,
    );
  }

  @override
  Event decryptEvent(EncryptedEvent encryptedEvent, Uint8List epochKey) {
    final map = cbor.decode(encryptedEvent.payload) as Map<dynamic, dynamic>;
    return Event.fromMap(map);
  }

  @override
  Uint8List encryptFeedKey(Uint8List feedKey, Uint8List sharedKey) {
    // Prepend 24-byte zero nonce, no encryption.
    final result = Uint8List(24 + feedKey.length);
    result.setRange(24, result.length, feedKey);
    return result;
  }

  @override
  Uint8List decryptFeedKey(Uint8List encryptedFeedKey, Uint8List sharedKey) {
    return Uint8List.sublistView(encryptedFeedKey, 24);
  }

  @override
  String computeEventId(Event event) {
    // Simple deterministic hash for testing. Emits Crockford base32 so the
    // mock matches the real service's event-id format.
    final idFieldsBytes = Uint8List.fromList(cbor.encode(event.toIdFields()));
    final result = Uint8List(32);
    for (var i = 0; i < idFieldsBytes.length; i++) {
      result[i % 32] ^= idFieldsBytes[i];
    }
    return crockfordBase32Encode(result);
  }

  @override
  EncryptedEvent encryptForAudience(Event event, Audience audience) {
    return encryptEvent(event, _mockFeedKey, 0);
  }
}
