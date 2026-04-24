# Finch

A private, peer-to-peer social feed. No servers, no ads, no algorithm. E2E encrypted, runs on your phone.

## Key documents

- `pitch.md` — product pitch and positioning
- `app/app-spec.md` — app architecture and spec
- `app/plans/` — implementation plans (01-15, sequential)
- `plans/finch-architecture.md` — system architecture overview
- `protocol/plans/protocol-spec.md` — protocol specification
- `relay/plans/relay-spec.md` — relay specification

## Architecture

- Flutter (Dart) app that acts as both client and server
- Crypto: libsodium via `sodium` Dart package v4 (Ed25519 identity, XChaCha20-Poly1305 feed encryption, BLAKE2b hashing, MegOLM-style feed key ratchet)
- Networking: embedded Arti (Tor) via Rust FFI for WAN, mDNS for LAN
- Storage: SQLCipher via drift
- Serialization: CBOR
- On-device HTTP server via shelf

## Constraints

- No servers, no backend, no corporation
- No monetization, free forever
- No push notifications
- App store distribution (not sideload-only) — avoid teen-specific marketing for compliance reasons
