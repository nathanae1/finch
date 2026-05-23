# Starling

A private, peer-to-peer social feed. No servers, no ads, no algorithm. E2E encrypted, runs on your phone.

## Key documents

- `pitch.md` — product pitch and positioning
- `app/app-spec.md` — app architecture and spec
- `app/plans/` — implementation plans (01-15, sequential)
- `plans/starling-architecture.md` — system architecture overview
- `protocol/plans/protocol-spec.md` — protocol specification
- `relay/plans/relay-spec.md` — relay specification

## Architecture

- Flutter (Dart) app that acts as both client and server
- Crypto: libsodium via `sodium` Dart package v4 (Ed25519 identity, XChaCha20-Poly1305 feed encryption, BLAKE2b hashing). MegOLM-shaped per-message keys: each post's AEAD key is derived as `BLAKE2b-256(chainRoot || "starling-msg-key-v1" || u64_be(msgSeq))`. Wire format carries `epoch` + `msg_seq` on every `EncryptedEvent`. Receivers archive prior chain roots in `follow_feed_key_history` so cached content stays decryptable across rotations. Derivation is currently flat (no within-epoch ratchet); a forward-secrecy upgrade swaps the derivation only, no wire change.
- Networking: embedded Arti (Tor) via Rust FFI for WAN, mDNS for LAN
- Storage: drift over sqlite3mc (SQLite Multiple Ciphers, SQLCipher v4 mode), key passed via `PRAGMA key`. Configured by the sqlite3 native asset hook in pubspec (`hooks.user_defines.sqlite3.source: sqlite3mc`).
- Serialization: CBOR
- On-device HTTP server via shelf

## Constraints

- No servers, no backend, no corporation
- No monetization, free forever
- No push notifications
- App store distribution (not sideload-only) — avoid teen-specific marketing for compliance reasons
