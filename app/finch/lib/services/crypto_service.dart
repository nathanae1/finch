import 'dart:typed_data';

import 'types.dart';

/// Narrow interface for cryptographic primitives.
///
/// Contains only stable, low-level operations: signing, verification,
/// symmetric encryption, hashing, key conversion, key derivation.
///
/// Feed key management, epoch ratchet, and composed operations
/// (sign-then-encrypt) live in [ContentKeyService], which uses
/// this interface for primitives.
abstract class CryptoService {
  // --- Key management ---

  Future<KeyPair> generateKeyPair();

  Future<List<String>> deriveRecoveryPhrase(Uint8List seed);

  Future<KeyPair> recoverFromPhrase(List<String> words);

  Uint8List ed25519ToX25519PublicKey(Uint8List ed25519Pk);

  Uint8List ed25519ToX25519SecretKey(Uint8List ed25519Sk);

  // --- Signing & verification ---

  Uint8List sign(Uint8List privateKey, Uint8List data);

  bool verify(Uint8List publicKey, Uint8List data, Uint8List signature);

  // --- Random bytes ---

  /// Cryptographically secure random bytes.
  Uint8List randomBytes(int length);

  // --- Symmetric encryption (XChaCha20-Poly1305) ---

  /// Low-level XChaCha20-Poly1305 encrypt with explicit nonce.
  /// Does not prepend nonce to output. Caller stores nonce separately
  /// (e.g. in [EncryptedEvent.nonce]).
  Uint8List encrypt(Uint8List plaintext, Uint8List nonce, Uint8List key);

  /// Low-level XChaCha20-Poly1305 decrypt with explicit nonce.
  /// Throws on authentication failure (wrong key / tampered ciphertext).
  Uint8List decrypt(Uint8List ciphertext, Uint8List nonce, Uint8List key);

  /// Encrypt a media blob. Generates a random 24-byte nonce and
  /// prepends it to the output: `nonce || ct`.
  Uint8List encryptMedia(Uint8List blob, Uint8List epochKey);

  /// Decrypt a media blob where the first 24 bytes are the nonce.
  Uint8List decryptMedia(Uint8List encryptedBlob, Uint8List epochKey);

  // --- Key exchange (X25519 DH + crypto_kdf, ctx "finchkex") ---

  /// Derive a shared key for feed key exchange.
  /// Uses X25519 DH + libsodium crypto_kdf with context parameters
  /// to ensure unique keys per exchange.
  Uint8List deriveSharedKey(
    Uint8List myPrivateKey,
    Uint8List theirPublicKey,
    Uint8List requesterPubkey,
    Uint8List responderPubkey,
    int timestamp,
  );

  // --- Hashing ---

  Uint8List blake2b256(Uint8List data);
}
