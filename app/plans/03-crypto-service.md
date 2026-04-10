# Plan 03: Crypto Service (libsodium FFI)

## Dependencies
Plan 01 (abstract CryptoService interface), Plan 02 (keychain storage patterns)

## Scope

Implement all cryptographic operations behind the `CryptoService` interface.

### libsodium binding
Use `sodium_libs` package (maintained, ships prebuilt binaries for iOS/Android). Provides direct FFI access to libsodium functions.

### Key management
- **Ed25519 keypair generation** — `crypto_sign_keypair()` on first launch
- **Recovery phrase** — BIP-39 style derivation:
  - Generate 256-bit entropy (or use Ed25519 seed)
  - Map to 24-word mnemonic using English BIP-39 word list
  - Reverse: mnemonic → seed → keypair
  - Ship `assets/bip39_english.txt` (2048 words)
  - Frame as "recovery phrase" in all UI/logs, never "seed phrase"
- **Private key storage** — store in OS keychain via `flutter_secure_storage`
- **Ed25519 → X25519 conversion** — `crypto_sign_ed25519_pk_to_curve25519()` / `crypto_sign_ed25519_sk_to_curve25519()`
- **Feed key generation** — 256-bit random key via `randombytes_buf(32)`

### Event operations
- `sign(event) → sig` — `crypto_sign_detached(sha256(cbor(event_fields)), sk)`
- `verify(event) → bool` — `crypto_sign_verify_detached(sig, id_bytes, pk)`
- `encrypt(event, feed_key) → EncryptedEvent` — sign first, then XChaCha20-Poly1305 encrypt serialized event with random 24-byte nonce
- `decrypt(encrypted_event, feed_key) → Event` — decrypt, then verify signature
- Event ID computation: `sha256(cbor(pubkey + created_at + kind + content))` — must match protocol spec exactly

### Media operations
- `encryptMedia(blob, feed_key) → encrypted_blob` — random 24-byte nonce prepended: `nonce || XChaCha20-Poly1305(key, nonce, blob)`
- `decryptMedia(encrypted_blob, feed_key) → blob` — split nonce from ciphertext, decrypt
- SHA-256 hash of plaintext for content addressing

### Key exchange
- `deriveSharedKey(my_x25519_sk, their_x25519_pk) → symmetric_key`
  - X25519 Diffie-Hellman → shared secret
  - HKDF-SHA256 with salt `"finch-feed-key-v1"` → 256-bit key
- `encryptFeedKey(feed_key, shared_key) → encrypted_feed_key` — XChaCha20-Poly1305 with random nonce
- `decryptFeedKey(encrypted_feed_key, shared_key) → feed_key`

### Nonce generation
All nonces are 24 bytes from CSPRNG (`randombytes_buf(24)`). Never derived from content. Never reused.

### Feed key cache
- On app launch: load feed keys for all followed accounts from DB, decrypt into in-memory `Map<String, Uint8List>`
- On terminate: clear the map
- Cache avoids per-event key derivation during feed rendering

## Files created/modified
- `lib/services/crypto/sodium_crypto_service.dart` — full CryptoService implementation
- `lib/services/crypto/recovery_phrase.dart` — BIP-39 word list + mnemonic derivation
- `lib/services/crypto/key_cache.dart` — in-memory feed key cache
- `assets/bip39_english.txt` — English word list (2048 words)
- `lib/providers/service_providers.dart` (update: wire real CryptoService)
- `test/services/crypto/crypto_service_test.dart`
- `test/services/crypto/recovery_phrase_test.dart`
- `test/services/crypto/key_exchange_test.dart`

## Verification
- Generate keypair, derive recovery phrase, re-derive keypair from phrase — keys match exactly
- Sign event, verify signature — passes
- Tamper with event after signing, verify — fails
- Encrypt event with feed key, decrypt — plaintext matches
- Encrypt with wrong key, decrypt — fails (authentication error)
- Encrypt media blob, decrypt — content matches, SHA-256 hash verifiable
- Key exchange: two keypairs perform DH, both derive same shared key
- Cross-device simulation: encrypt feed key on "Alice", decrypt on "Bob" using exchanged key
- Nonces: encrypt same content twice, ciphertexts differ (random nonces)
- Recovery phrase: use BIP-39 test vectors to validate derivation
- All operations work on iOS and Android real devices (not just simulators)

## Key decisions
- `sodium_libs` package for libsodium (prebuilt binaries, maintained). If it breaks on a platform, fall back to manual FFI with `flutter_sodium` or raw `dart:ffi`.
- BIP-39 English word list only for MVP. Other languages can be added later.
- 24-word recovery phrase (256-bit entropy) matching Ed25519 seed size.
- Sign-then-encrypt order per protocol spec. This is critical — get it right from day one.

## Risks
- FFI crashes on specific platforms/architectures. Test on real devices early, not just simulators.
- BIP-39 derivation must be byte-for-byte correct or recovery fails. Use published test vectors.
- Large media blobs (5-10MB photos) encrypted in memory could cause pressure. Consider streaming encryption for large files, or process in a separate isolate.
