# Plan 03: Crypto Service (libsodium via `sodium` package)

## Dependencies
Plan 01 (abstract CryptoService interface), Plan 02 (keychain storage patterns)

## Scope

Implement all cryptographic operations behind the `CryptoService` interface using the `sodium` Dart package (v4), which wraps the audited libsodium C library via Dart native asset build hooks.

### Architecture: CryptoService vs ContentKeyService

Per Plan 01, crypto is split into two layers:
- **CryptoService** — narrow interface for crypto primitives: sign, verify, encrypt-symmetric, decrypt-symmetric, hash, random-bytes, key-convert. Stable forever (because libsodium isn't changing).
- **ContentKeyService** — feed key generation, ratchet (epoch advancement), feed key encryption/decryption for followers, audience resolution. Uses CryptoService for primitives. This is the layer that evolves when MLS arrives — it gets a second implementation, not a rewrite of the first.

This plan implements both.

### Library choice
Use `sodium` package v4 (single dependency — `sodium_libs` was discontinued in March 2026 and folded into `sodium`). Ships prebuilt libsodium binaries for iOS and Android via Dart native assets. All hashing uses BLAKE2b (libsodium's native hash) instead of SHA-256, eliminating the need for any additional crypto dependency.

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
- **Feed key generation** — 256-bit random key via `randombytes_buf(32)` (epoch 0)

### Feed key ratchet (MegOLM-style) — ContentKeyService
- `advanceEpoch(currentKey) → nextKey` — `BLAKE2b-256(currentKey || "finch-ratchet-v1")`
- Epoch advances periodically (daily or every N posts)
- New followers receive current epoch key, can derive forward but not backward
- On unfollow: force-advance to a new random key (breaks the chain)
- Lives on ContentKeyService, not CryptoService

### Event operations
- `sign(event) → sig` — `crypto_sign_detached(blake2b_256(cbor(event_id_fields)), sk)` (CryptoService)
- `verify(event) → bool` — `crypto_sign_verify_detached(sig, id_bytes, pk)` (CryptoService)
- `encrypt(event, epoch_key) → EncryptedEvent` — sign first, then XChaCha20-Poly1305 encrypt serialized event with random 24-byte nonce (CryptoService provides symmetric encryption; ContentKeyService resolves which key to use)
- `decrypt(encrypted_event, epoch_key) → Event` — decrypt, then verify signature
- Event ID computation: `blake2b_256(cbor(version + pubkey + created_at + kind + ref + content + media + extensions))` — includes all fields except `id` and `sig`. `version` is included to prevent downgrade attacks. `extensions` is included so item-level extensions are inside the signature by default (see protocol spec Envelope Trust Model). Pass an empty map `{}` when no extensions are present.

### Media operations
- `encryptMedia(blob, epoch_key) → encrypted_blob` — random 24-byte nonce prepended: `nonce || XChaCha20-Poly1305(key, nonce, blob)`
- `decryptMedia(encrypted_blob, epoch_key) → blob` — split nonce from ciphertext, decrypt
- BLAKE2b-256 hash of plaintext for content addressing

### Key exchange
- `deriveSharedKey(my_x25519_sk, their_x25519_pk, requester_pk, responder_pk, timestamp) → symmetric_key` (CryptoService — this is a primitive)
  - X25519 Diffie-Hellman → shared secret
  - `crypto_kdf_derive_from_key(subkey_len=32, subkey_id=1, ctx="finchkex", key=shared_secret)` with `info = requester_pubkey || responder_pubkey || timestamp`
  - Unique per exchange (no static salt reuse between same parties)
- `encryptFeedKey(feed_key, shared_key) → encrypted_feed_key` — XChaCha20-Poly1305 with random nonce (ContentKeyService)
- `decryptFeedKey(encrypted_feed_key, shared_key) → feed_key` (ContentKeyService)

### Nonce generation
All nonces are 24 bytes from CSPRNG (`randombytes_buf(24)`). Never derived from content. Never reused.

### Feed key cache (ContentKeyService)
- On app launch: load feed keys for all followed accounts from DB, decrypt into in-memory `Map<String, Uint8List>`
- On terminate: clear the map
- Cache avoids per-event key derivation during feed rendering

### Publish pipeline
The full publish flow uses the Audience abstraction:
1. Build `Event` (with `Clock` for timestamp)
2. Resolve `Audience` → for v1, always `Audience.broadcast`
3. `ContentKeyService.encryptForAudience(event, audience)` → sign, encrypt with current feed key, wrap in `EncryptedEvent`
4. Wrap in `EnvelopeItem(type: "event", payload: serialized_encrypted_event)`
5. Wrap in `Envelope(version, items, extensions: {})`
6. Hand to transport for delivery

## Files created/modified
- `lib/services/crypto/sodium_crypto_service.dart` — CryptoService implementation (primitives only: sign, verify, encrypt-symmetric, decrypt-symmetric, hash, random-bytes, key-convert)
- `lib/services/crypto/pairwise_content_key_service.dart` — ContentKeyService implementation (feed key management, ratchet, audience resolution, feed key encryption for followers)
- `lib/services/crypto/recovery_phrase.dart` — BIP-39 word list + mnemonic derivation
- `lib/services/crypto/feed_key_ratchet.dart` — MegOLM-style epoch key advancement (used by ContentKeyService)
- `lib/services/crypto/key_cache.dart` — in-memory feed key cache (used by ContentKeyService)
- `assets/bip39_english.txt` — English word list (2048 words)
- `lib/services/crypto_service.dart` (update: narrow to primitives — sign, verify, encrypt, decrypt, hash, random, key-convert. Remove feed key and epoch methods.)
- `lib/services/content_key_service.dart` (update: add `advanceEpoch`, `encryptFeedKey`, `decryptFeedKey`, `encryptForAudience`, `getCurrentFeedKey`)
- `lib/services/mocks/mock_crypto_service.dart` (update: match narrowed interface)
- `lib/services/mocks/mock_content_key_service.dart` (update: match new interface)
- `lib/models/encrypted_event.dart` (update: add `epoch` field)
- `lib/models/event.dart` (update: `toIdFields()` to include `version`, `ref`, `media`, and `extensions`)
- `lib/providers/service_providers.dart` (update: wire real CryptoService + ContentKeyService)
- `test/services/crypto/crypto_service_test.dart`
- `test/services/crypto/content_key_service_test.dart`
- `test/services/crypto/recovery_phrase_test.dart`
- `test/services/crypto/key_exchange_test.dart`
- `test/services/crypto/feed_key_ratchet_test.dart`
- `test/vectors/` — shared test vector directory (see below)

## Verification
- Generate keypair, derive recovery phrase, re-derive keypair from phrase — keys match exactly
- Sign event, verify signature — passes
- Tamper with event after signing, verify — fails
- Encrypt event with epoch key, decrypt — plaintext matches
- Encrypt with wrong key, decrypt — fails (authentication error)
- Encrypt media blob, decrypt — content matches, BLAKE2b-256 hash verifiable
- Key exchange: two keypairs perform DH, both derive same shared key
- Key exchange: same parties with different timestamps derive different shared keys
- Cross-device simulation: encrypt feed key on "Alice", decrypt on "Bob" using exchanged key
- Nonces: encrypt same content twice, ciphertexts differ (random nonces)
- Recovery phrase: use BIP-39 test vectors to validate derivation
- Feed key ratchet: advance epoch, verify forward derivation works, verify backward derivation is impossible
- Event ID includes version, ref, media, and extensions: two comments with same text on different posts produce different IDs; changing version changes ID; adding extensions changes ID
- Event ID with empty extensions map produces same hash consistently
- ContentKeyService.encryptForAudience produces a valid EncryptedEvent wrappable in an EnvelopeItem
- All operations work on iOS and Android real devices (not just simulators)

### Test vectors
Seed the `test/vectors/` directory with at least 5 known-answer test vectors:
1. **Keypair derivation**: given this seed → this Ed25519 keypair → this X25519 conversion
2. **Event ID**: given these specific fields (including version and empty extensions) → this exact BLAKE2b-256 hash
3. **Event signing**: given this keypair and this event → this exact signature
4. **Feed key ratchet**: given epoch key 0 → epoch key 1 → epoch key 2 (exact bytes)
5. **Event encryption**: given this feed key and this nonce → this exact EncryptedEvent payload

Vector format: `test/vectors/index.json` lists each vector with type, CBOR file path, and expected decoded field values as JSON. Both the Dart app tests and the future Rust relay tests read the same index and assert the same values. This pins the protocol against future refactors and catches serialization divergence between implementations.

## Key decisions
- `sodium` package v4 (single dependency, audited libsodium, native asset build hooks). If it breaks on a platform, fall back to manual FFI with raw `dart:ffi`.
- BLAKE2b-256 everywhere instead of SHA-256 — keeps everything in libsodium, no additional crypto packages needed.
- `crypto_kdf` with context parameters instead of HKDF-SHA256 — unique keys per exchange, all from libsodium.
- MegOLM-style hash ratchet for feed keys — forward secrecy for new followers without Signal Protocol complexity.
- BIP-39 English word list only for MVP. Other languages can be added later.
- 24-word recovery phrase (256-bit entropy) matching Ed25519 seed size.
- Sign-then-encrypt order per protocol spec. This is critical — get it right from day one.
- CryptoService is narrow (primitives only). ContentKeyService holds all feed key and audience logic. This keeps crypto primitives stable and puts the volatile group-key design in a layer that can gain a second implementation (MLS) without touching primitives.
- `version` included in Event ID hash to prevent downgrade attacks.
- `extensions` included in Event ID hash so item-level extensions are inside the signature by default (protocol spec trust model, Rule 4).
- All timestamps come from injected `Clock`, never bare `DateTime.now()`.

## Risks
- FFI crashes on specific platforms/architectures. Test on real devices early, not just simulators.
- BIP-39 derivation must be byte-for-byte correct or recovery fails. Use published test vectors.
- Large media blobs (5-10MB photos) encrypted in memory could cause pressure. Consider streaming encryption for large files, or process in a separate isolate.
- `crypto_kdf` context field is limited to 8 bytes — "finchkex" fits exactly. The info (pubkeys + timestamp) must be passed via the key material, not the context.
