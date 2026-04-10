import 'dart:typed_data';

import '../models/models.dart';
import 'types.dart';

/// Abstract interface for all cryptographic operations.
///
/// Default implementation wraps libsodium via FFI (Plan 03).
/// Mock implementation provides deterministic values for testing.
abstract class CryptoService {
  // --- Key management ---

  Future<KeyPair> generateKeyPair();

  Future<List<String>> deriveRecoveryPhrase(Uint8List seed);

  Future<KeyPair> recoverFromPhrase(List<String> words);

  Future<Uint8List> generateFeedKey();

  Uint8List ed25519ToX25519PublicKey(Uint8List ed25519Pk);

  Uint8List ed25519ToX25519SecretKey(Uint8List ed25519Sk);

  // --- Signing & verification ---

  Uint8List sign(Uint8List privateKey, Uint8List data);

  bool verify(Uint8List publicKey, Uint8List data, Uint8List signature);

  // --- Event encryption (sign-then-encrypt / decrypt-then-verify) ---

  EncryptedEvent encryptEvent(Event event, Uint8List feedKey);

  Event decryptEvent(EncryptedEvent encryptedEvent, Uint8List feedKey);

  // --- Media encryption ---

  Uint8List encryptMedia(Uint8List blob, Uint8List feedKey);

  Uint8List decryptMedia(Uint8List encryptedBlob, Uint8List feedKey);

  // --- Key exchange (X25519 DH + HKDF-SHA256, salt "finch-feed-key-v1") ---

  Uint8List deriveSharedKey(Uint8List myPrivateKey, Uint8List theirPublicKey);

  Uint8List encryptFeedKey(Uint8List feedKey, Uint8List sharedKey);

  Uint8List decryptFeedKey(Uint8List encryptedFeedKey, Uint8List sharedKey);

  // --- Hashing ---

  Uint8List sha256(Uint8List data);

  String computeEventId(Event event);
}
