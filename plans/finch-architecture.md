# Finch — Private Social for Your Real Friends

## Context

Finch is a peer-to-peer social feed app where your data never touches a server you don't control. No accounts, no algorithms, no ads, no corporation between you and your friends. Every photo, every post, every reaction lives on the devices of the people in the conversation — and nowhere else.

Finch is the first product in a broader vision: a platform that makes self-hosting normal. Today it's a social feed. Tomorrow it's messaging, media, and more — all built on the same identity and networking primitives, all owned by the user.

**Target audience**: People who are tired of algorithmic social media and want a private space with their real friends. Not people who care about cryptography — people who care about not being monetized. The crypto is invisible; the experience is what matters.

**Positioning**: Favs and BeReal proved that "close friends, no algorithm" resonates. But they're centralized, VC-funded, and will eventually decay (BeReal already has ads). Manyverse proved P2P social works technically, but nobody uses it because the UX is brutal. Finch sits in the gap: P2P architecture with consumer-grade UX. Your data stays yours not because of a privacy policy that can change, but because of math that can't.

## Design Principles

1. **No developer-operated infrastructure.** Finch the project runs zero servers. Not relays, not push proxies, not signaling servers. Every piece of infrastructure is on a device the user owns.
2. **Free forever.** No monetization, no paid tiers, no managed hosting. This is a public good, not a business.
3. **The crypto is invisible.** Users never see a key, a hash, or a signature. They see friends, posts, and photos. The encryption is load-bearing but silent.
4. **Async by design.** Posts arrive when your friends are around, not instantly. This isn't a bug — it's a deliberate departure from addictive, always-on social media. The slower pace is the product.
5. **Self-hosting is a gradient, not a prerequisite.** The app works phone-to-phone with zero setup. Running a relay on an old device is the first step up. Running a server on a VPS is the next. Each step gives more availability, not more features.

## Architecture Overview

### Identity

- **Ed25519 keypair** generated on device at first launch
- Public key = identity, displayed as a short base32 string (e.g., `finch:a3kx9m...`)
- Profile data (display name, bio, avatar) is a signed event, same as any other content
- Key backup via seed phrase — but framed as "recovery phrase" in the UI, not crypto jargon
- No usernames, no central registry, no accounts

### Encryption

All content is encrypted before it leaves your device. There is no plaintext path.

**Key hierarchy:**
```
Identity Key (Ed25519)
  +-- X25519 conversion (for key exchange with followers)
  +-- Feed Key (XChaCha20-Poly1305 symmetric key)
       +-- encrypts all your events + media
```

- **Feed key**: A symmetric key you generate. Posts are encrypted with the current epoch key, which advances forward via a hash ratchet (MegOLM-style). New followers receive the current key and can derive future keys but not past ones. You share it with each follower individually via X25519 Diffie-Hellman key exchange.
- **At rest on device**: Local SQLite DB encrypted via SQLCipher. Media files encrypted with a device-local key stored in OS keychain.
- **In transit**: Content payloads are E2E encrypted. LAN connections expose HTTP metadata (request paths, timing) to local network observers — accepted trade-off for LAN simplicity. Tor connections are fully private.
- **On relay (if configured)**: Relay stores encrypted blobs it cannot decrypt. It sees only: pubkey, timestamps, blob sizes.

### Content Model

Everything is a **signed-then-encrypted event**:

```
Event (plaintext, before encryption) {
  version:    date-based protocol version (e.g., "2026-03-24")
  id:         blake2b_256(version + pubkey + created_at + kind + ref + content + media + extensions)
  pubkey:     creator's Ed25519 public key
  created_at: unix timestamp
  kind:       1=post, 2=profile, 3=follow_list, 4=comment, 5=like, 6=delete (open enum — see protocol spec for ranges)
  ref:        optional reference to another event id
  content:    kind-specific payload
  media:      [{ hash, mime_type, size }]
  extensions: Map<string, bytes> (empty map if none — included in ID hash and signature)
  sig:        Ed25519 signature over id
}

EncryptedEvent (what gets stored in Envelopes) {
  pubkey:     creator's public key (plaintext, needed for routing)
  created_at: unix timestamp (plaintext, needed for sync)
  epoch:      feed key epoch number
  nonce:      random 24 bytes (unique per event)
  payload:    XChaCha20-Poly1305(epoch_key, nonce, serialized Event)
}

Envelope (what transports actually move) {
  version:    protocol version
  items:      [EnvelopeItem { type, payload, extensions }]
  extensions: Map<string, bytes> (untrusted — see protocol spec trust model)
}
```

Sign first, then encrypt. Followers decrypt, then verify signature. Media blobs encrypted separately with the same feed key, each with a random nonce.

### Networking — Two-Tier Connectivity

**Tier 1 — LAN (fastest, zero config):**
- Phone runs a lightweight HTTP server on a high port
- Discoverable via mDNS/Bonjour on local network
- Direct device-to-device sync, sub-second latency
- Perfect for syncing with friends at school, at home, hanging out

**Tier 2 — Tor signaling + WAN hole-punch (fast, best-effort):**
- Phone creates a Tor onion service via embedded Arti (Rust Tor client)
- `.onion` address is stable and included in the connection card
- When two peers connect over Tor, they attempt to upgrade to a direct WAN connection:
  1. Both peers discover their public IP:port via STUN
  2. Exchange public endpoints over the Tor connection (small payload, latency acceptable)
  3. Attempt simultaneous TCP/UDP open (NAT hole-punching)
  4. If successful: data flows directly, 50-200ms latency
  5. If failed (~30% of NAT configurations): fall back to Tor for data transfer
- STUN servers are external infrastructure, but stateless and content-blind — they learn your IP (which they already see) and nothing else. App ships with public STUN defaults (Google, Cloudflare). Users can configure their own.

**Tier 2 fallback — Tor data transfer:**
- When hole-punching fails, all sync traffic flows over Tor
- 3-5 second latency per request — acceptable for async feed sync
- This is the universal fallback that always works
- Onion service only runs in foreground (iOS) or via foreground service (Android opt-in)

**Connection card** (encoded in QR codes / shareable links):
```
{
  pubkey: "ed25519_public_key",
  endpoints: [
    { type: "onion", address: "abc123...xyz.onion" },
    { type: "relay", url: "https://..." }  // only if relay configured
  ]
}
```

### Sync Model

Finch is an **async social feed**, not a real-time messenger. Content propagates through direct peer connections. You don't need any peer to be online right now — you need them to have been online at some point since the content was posted, overlapping with another peer who had it.

**On app open:**
1. Build want list: for each followed pubkey, what events are we missing in the sync window (default 30 days)?
2. Discover peers: mDNS scan (LAN) + connection card endpoints for followed accounts
3. Exchange manifests with reachable peers: lightweight list of event IDs
4. Pull missing events from fastest available source (LAN > relay > Tor)
5. Decrypt, verify signatures, store locally
6. Our device now serves this content to other peers who ask

**Each device only stores:**
- Your own content (permanent, you are the source of truth)
- Content from groups/people you follow (your copy of the conversation, subject to retention policy)

**Media**: Fetched lazily when a post scrolls into view. Any peer that has a copy can serve it.

### Discovery & Following

- **QR code**: Scan in person — adds their connection card to your follow list
- **Invite link**: `finch://connect?card={base64url}` — tap to follow, one step
- **No global search, no explore page, no algorithmic feed, no suggested friends**
- You find people the way you find phone numbers — someone gives you theirs

**Follow handshake:**
1. Alice scans Bob's QR or taps his invite link
2. Alice sends a follow request to Bob's endpoint (including her pubkey + encrypted return endpoints)
3. Bob accepts on his device — encrypts his feed key for Alice using X25519 DH and sends it back
4. Alice can now decrypt Bob's posts
5. Mutual follows require both sides to initiate

### Data Ownership

- All your data lives on your phone (and optionally your relay)
- You can export everything as a signed bundle at any time
- Deleting the app = deleting your data (unless backed up)
- Followers have cached copies of posts they've synced — this is by design (you shared it with them)
- You can publish a "delete" event that well-behaved clients honor, but you can't force deletion from someone else's device (same as real life)

## Self-Hosting Gradient

Finch works phone-to-phone with zero infrastructure. But availability improves as you add infrastructure you control:

**Level 0 — Phones only (default):**
Content syncs when your phone and your friends' phones are online at the same time. Works great when you're physically together or both active. Content may be delayed when nobody with it is online.

**Level 1 — Spare device relay:**
Install Finch on an old phone or tablet, pair it with your main device, leave it on WiFi. It becomes an always-on relay that serves your content 24/7 via Tor. Your friends can fetch your posts anytime, even when your main phone is off. Zero technical knowledge required — it's just another Finch install with a toggle flipped.

**Level 2 — Standalone relay (Rust binary):**
For self-hosters: a headless Rust binary that runs on a Raspberry Pi, a NAS, a VPS, or a Proxmox container. Reachable via domain + TLS or Tor onion. Same zero-knowledge model — stores encrypted blobs, can't read them.

Each level adds availability, not features. The app is fully functional at Level 0.

## The Broader Vision

Finch is the steel thread. The identity system, encryption, P2P networking, and self-hosting patterns it establishes are the foundation for a larger ecosystem:

- **Social feed** (Finch v1) — photos and posts with your real friends
- **Messaging** — real-time chat, requires Level 1+ for reliable delivery
- **Media sharing** — longer-form content, video
- **And beyond** — each new capability is a module on the same identity and networking layer

The goal is to make self-hosting normal by starting with something people actually want to use, not something they have to be convinced to care about.

## Tech Stack

- **Mobile app**: Flutter (single codebase, iOS + Android + desktop)
- **On-device server**: Dart `shelf` package
- **Local storage**: SQLCipher (encrypted SQLite)
- **Crypto**: libsodium via `sodium` Dart package (v4, uses Dart native asset build hooks)
- **Tor**: Arti (Rust Tor client) via FFI
- **Relay (standalone)**: Rust, SQLite, single static binary
- **Serialization**: CBOR
- **State management**: Riverpod (`flutter_riverpod` + `riverpod_generator`)

### Native Interop Strategy

All native library interop (libsodium, Arti, SQLCipher) is isolated behind abstract Dart service interfaces: `CryptoService`, `TorService`, `StorageService`. App logic and UI depend only on these interfaces, never on FFI types directly. This gives testability (mock implementations), swappability (replace a native library without touching app logic), and an escape hatch to platform channels (Swift/Kotlin) if FFI proves unreliable for a specific service.

## MVP Scope

Phase 1 — what ships first:
1. Identity generation + recovery phrase backup
2. Profile creation (name, avatar)
3. Post photos with captions
4. Invite links + QR code scanning for follow flow
5. Follow handshake with key exchange
6. LAN sync (mDNS discovery + local HTTP + manifest exchange)
7. Tor onion service for WAN sync
8. Chronological feed with lazy media loading
9. Encrypted local storage
10. Comments and reactions on posts
11. Feed key rotation on unfollow
12. Spare-device relay: turn an old phone into a personal always-on server

**Deferred**: Multi-device pairing, standalone Rust relay binary, direct WAN hole-punching, video, DMs, media cache management UI.

## Competitive Landscape

| | Favs | BeReal | Manyverse | Finch |
|---|---|---|---|---|
| Private friend groups | Yes | Sort of | Yes | Yes |
| No algorithm / no ads | Yes (for now) | No (ads 2025) | Yes | Yes (forever) |
| User owns data | No (VC servers) | No | Yes | Yes |
| No server required | No | No | Yes | Yes |
| Consumer-grade UX | Yes | Yes | No | Goal |
| Sustainable model | VC (will decay) | VC (decaying) | Grants (fragile) | Free (no infra costs) |

The gap: nobody has shipped a P2P, serverless, private social feed with consumer-grade UX. Manyverse proves the architecture. Favs proves the demand. Finch combines them.
