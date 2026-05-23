import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import '../crypto_service.dart';
import '../types.dart' as starling;
import 'recovery_phrase.dart';

/// Real [CryptoService] implementation backed by libsodium (sumo variant).
///
/// The sumo variant is required for the Ed25519 ↔ X25519 key conversion
/// helpers on [SignSumo], which do not exist in the standard build.
///
/// All primitives delegate directly to libsodium. Event / feed key / audience
/// logic lives in `PairwiseContentKeyService`, not here.
class SodiumCryptoService implements CryptoService {
  SodiumCryptoService._(this._sodium);

  final SodiumSumo _sodium;

  /// Initialize libsodium and return a ready service.
  ///
  /// Call once at app startup (see `main.dart`) and cache the result.
  static Future<SodiumCryptoService> init() async {
    final sodium = await SodiumSumoInit.init();
    return SodiumCryptoService._(sodium);
  }

  // --- Key management ---

  @override
  Future<starling.KeyPair> generateKeyPair() async {
    final kp = _sodium.crypto.sign.keyPair();
    try {
      return starling.KeyPair(
        publicKey: Uint8List.fromList(kp.publicKey),
        secretKey: kp.secretKey.extractBytes(),
      );
    } finally {
      kp.dispose();
    }
  }

  @override
  Future<List<String>> deriveRecoveryPhrase(Uint8List seed) async {
    return RecoveryPhrase.toWords(seed, blake2b256);
  }

  @override
  Future<starling.KeyPair> recoverFromPhrase(List<String> words) async {
    final seedBytes = await RecoveryPhrase.toSeed(words, blake2b256);
    final seed = SecureKey.fromList(_sodium, seedBytes);
    try {
      final kp = _sodium.crypto.sign.seedKeyPair(seed);
      try {
        return starling.KeyPair(
          publicKey: Uint8List.fromList(kp.publicKey),
          secretKey: kp.secretKey.extractBytes(),
        );
      } finally {
        kp.dispose();
      }
    } finally {
      seed.dispose();
    }
  }

  @override
  Uint8List ed25519ToX25519PublicKey(Uint8List ed25519Pk) {
    return _sodium.crypto.sign.pkToCurve25519(ed25519Pk);
  }

  @override
  Uint8List ed25519ToX25519SecretKey(Uint8List ed25519Sk) {
    final sk = SecureKey.fromList(_sodium, ed25519Sk);
    try {
      final x25519 = _sodium.crypto.sign.skToCurve25519(sk);
      try {
        return x25519.extractBytes();
      } finally {
        x25519.dispose();
      }
    } finally {
      sk.dispose();
    }
  }

  // --- Signing & verification ---

  @override
  Uint8List sign(Uint8List privateKey, Uint8List data) {
    final sk = SecureKey.fromList(_sodium, privateKey);
    try {
      return _sodium.crypto.sign.detached(message: data, secretKey: sk);
    } finally {
      sk.dispose();
    }
  }

  @override
  bool verify(Uint8List publicKey, Uint8List data, Uint8List signature) {
    try {
      return _sodium.crypto.sign.verifyDetached(
        message: data,
        signature: signature,
        publicKey: publicKey,
      );
    } catch (_) {
      return false;
    }
  }

  // --- Random bytes ---

  @override
  Uint8List randomBytes(int length) => _sodium.randombytes.buf(length);

  // --- Symmetric encryption (XChaCha20-Poly1305) ---

  @override
  Uint8List encrypt(Uint8List plaintext, Uint8List nonce, Uint8List key) {
    final k = SecureKey.fromList(_sodium, key);
    try {
      return _sodium.crypto.aeadXChaCha20Poly1305IETF.encrypt(
        message: plaintext,
        nonce: nonce,
        key: k,
      );
    } finally {
      k.dispose();
    }
  }

  @override
  Uint8List decrypt(Uint8List ciphertext, Uint8List nonce, Uint8List key) {
    final k = SecureKey.fromList(_sodium, key);
    try {
      return _sodium.crypto.aeadXChaCha20Poly1305IETF.decrypt(
        cipherText: ciphertext,
        nonce: nonce,
        key: k,
      );
    } finally {
      k.dispose();
    }
  }

  @override
  Uint8List encryptMedia(Uint8List blob, Uint8List epochKey) {
    final nonce = randomBytes(24);
    final ct = encrypt(blob, nonce, epochKey);
    final result = Uint8List(nonce.length + ct.length);
    result.setRange(0, nonce.length, nonce);
    result.setRange(nonce.length, result.length, ct);
    return result;
  }

  @override
  Uint8List decryptMedia(Uint8List encryptedBlob, Uint8List epochKey) {
    if (encryptedBlob.length < 24) {
      throw ArgumentError('encrypted blob too short (< 24 bytes for nonce)');
    }
    final nonce = Uint8List.fromList(encryptedBlob.sublist(0, 24));
    final ct = Uint8List.fromList(encryptedBlob.sublist(24));
    return decrypt(ct, nonce, epochKey);
  }

  // --- Key exchange ---

  @override
  Uint8List deriveSharedKey(
    Uint8List myPrivateKey,
    Uint8List theirPublicKey,
    Uint8List requesterPubkey,
    Uint8List responderPubkey,
    int timestamp,
  ) {
    // Step 1: X25519 Diffie-Hellman. Returns a SecureKey with the raw shared
    // secret.
    final mySk = SecureKey.fromList(_sodium, myPrivateKey);
    SecureKey? sharedSecret;
    SecureKey? keyMaterial;
    SecureKey? derived;
    try {
      sharedSecret = _sodium.crypto.scalarmult.call(
        n: mySk,
        p: theirPublicKey,
      );
      final rawShared = sharedSecret.extractBytes();

      // Step 2: incorporate info into key material via BLAKE2b-256.
      // info = sharedSecret || requesterPk || responderPk || timestamp_le64
      final timestampBytes = Uint8List(8);
      final bd = ByteData.sublistView(timestampBytes);
      bd.setInt64(0, timestamp, Endian.little);

      final infoLen = rawShared.length +
          requesterPubkey.length +
          responderPubkey.length +
          timestampBytes.length;
      final info = Uint8List(infoLen);
      var offset = 0;
      info.setRange(offset, offset + rawShared.length, rawShared);
      offset += rawShared.length;
      info.setRange(offset, offset + requesterPubkey.length, requesterPubkey);
      offset += requesterPubkey.length;
      info.setRange(offset, offset + responderPubkey.length, responderPubkey);
      offset += responderPubkey.length;
      info.setRange(offset, offset + timestampBytes.length, timestampBytes);

      final keyMaterialBytes = blake2b256(info);
      keyMaterial = SecureKey.fromList(_sodium, keyMaterialBytes);

      // Step 3: crypto_kdf_derive_from_key with fixed context "starlingkex".
      derived = _sodium.crypto.kdf.deriveFromKey(
        masterKey: keyMaterial,
        context: 'starlingkex',
        subkeyId: BigInt.one,
        subkeyLen: 32,
      );
      return derived.extractBytes();
    } finally {
      derived?.dispose();
      keyMaterial?.dispose();
      sharedSecret?.dispose();
      mySk.dispose();
    }
  }

  // --- Hashing ---

  @override
  Uint8List blake2b256(Uint8List data) {
    return _sodium.crypto.genericHash(message: data, outLen: 32);
  }
}
