# Plan 15: Desktop Starling as Relay Mode

## Dependencies
Plan 07 (HTTP server), Plan 11 (Tor / Arti), Plan 13 (out-of-band key-distribution pattern), Plan 14 (lifecycle manager).

Replaces the abandoned spare-phone relay. Spare-phone Relay isn't reliable in practice — OEM kills (Xiaomi, Samsung, Huawei, OPPO, Vivo), Doze + App Standby budgets, no iOS analog, and flaky Wi-Fi roaming make a phone-based 24/7 server fragile. The Owner runs a **desktop Flutter build** of Starling (macOS first, then Linux/Windows) on hardware they actually leave on. Standalone Rust binary is Plan 15c. Settings polish is Plan 15b.

## Scope

Ship a desktop build of the existing Flutter app that boots into **Relay mode** instead of social UI. The Relay is the same `lib/` codebase: same `StarlingHttpServer`, same Arti onion service, same drift-on-SQLCipher storage, same Ed25519 sign/verify. What changes is the boot path, three new endpoints, a small set of new tables, and a minimal dashboard.

The Owner's phone gets a pairing entry point and a `relay`-typed `Endpoint` added to its own Connection card, distributed to existing Followers via a `connection_card_update` field piggybacked on `/manifest` — mirroring Plan 13's Feed-key distribution.

### Mode selection

Single `main.dart` entry. After bindings + storage init, read `app_mode` from `KeychainManager`:

- `null` on desktop → one-shot **Mode picker** ("Run as Starling" vs "Run as Relay"); mobile defaults to `social`
- `"social"` → existing `StarlingApp` shell, unchanged
- `"relay"` → new `RelayApp` shell

Both modes share the binary, dependencies, and most services. Only the router and the HTTP server's mounted handlers diverge.

### Pairing handshake

**Relay first-run (post-mode-pick, pre-pair):**

1. Generate a 32-byte `pairing_token`. Persist in `relay_pairing` (`token`, `created_at`, `expires_at = created_at + 600`, `consumed_at NULL`)
2. Bring up Arti onion service via existing `ArtiTorService`
3. Render `starling-relay://pair?card={base64url(CBOR{relay_onion, pairing_token, relay_version})}` using `StarlingQRCode`
4. Show plaintext onion + 8-char token suffix as fallback

**Phone scan (extending `lib/screens/friends/scan_screen.dart` and `connection_card_parser.dart`):**

1. Build `claim = blake2b_256("starling-relay-pair-v1" || owner_pubkey || relay_onion || pairing_token)`
2. Sign with Owner's Ed25519 secret key (`SodiumCryptoService.sign`)
3. POST to `http://<relay_onion>:80/pair` over Tor: CBOR `{ owner_pubkey, pairing_token, sig }`

**Relay `/pair` handler:**

1. Reject if `consumed_at != null` → 409 (one-shot)
2. Reject if expired → 410
3. Constant-time compare token
4. Recompute `claim`, verify `sig` via `SodiumCryptoService.verify`
5. On success: write `relay_paired_owner` row, set `relay_pairing.consumed_at = now`, return CBOR `{ relay_onion, relay_id: blake2b_256(owner_pubkey || relay_onion) }`

Replay protection: single-use token, 10-minute TTL, bound into the signed claim along with the Relay's onion so a captured token can't redirect to a different Relay.

### State after pairing

**Relay side:** singleton `relay_paired_owner(pubkey, bound_at)`. All write endpoints check `X-Starling-Pubkey` against this row.

**Phone side:** new `paired_relay(relay_id, relay_onion, paired_at)` row. Append `Endpoint(type: 'relay', address: '<relay_onion>')` to the Owner's Connection card (no schema change — `connection_card.dart` already supports `"relay"`).

**Distributing the card update to existing Followers:** piggyback on `/manifest`. The response gains an optional `connection_card_update` field: CBOR `{ card: ConnectionCard, sig: Ed25519(card_bytes), created_at }`. Followers verify against the Owner's pubkey (already in their `Follow` row) and replace `follows.connectionCard`. A new `pending_card_distributions` table on the publisher side mirrors `pending_key_distributions_table.dart` — one row per Follower, cleared on ack. This avoids forcing existing Friends to re-scan.

### Push flow (phone → Relay)

Implement `pushEvents()` / `pushMedia()` in `lan_network_service.dart:249-263` (replacing the existing `UnimplementedError`):

```
pushEvents → POST {baseUrl}/events, body = CBOR(Envelope([EnvelopeItem('event', enc_event)])),
             headers {X-Starling-Sig: base64(Ed25519.sign(owner_sk, blake2b_256(body))), X-Starling-Pubkey}
pushMedia  → POST {baseUrl}/media/{hash}, body = encrypted blob, same auth headers
```

Same `LanNetworkService` instance handles LAN and Relay pushes — only `PeerConnection.transport` and `baseUrl` differ. The Tor `http.Client` swap from Plan 11 covers the Relay transport.

**Trigger sites:**

- **Foreground, immediately after publish** — extend `DefaultPostFanoutService.fanout()` (`lib/services/post_fanout_service.dart`). If `paired_relay` exists, push the same envelope to the Relay alongside Follower pushes. Best-effort.
- **Outbound queue drain** — extend `lib/sync/outbound_drain.dart` to handle relay-targeted rows; reuses `reconnect_pusher.dart` connectivity-change triggers.
- **Media** — push when `MediaService` finishes encrypting; one-shot.
- **Initial backfill on first pair** — one-shot iterator over own events + media; progress in the Relay dashboard; gated on `relay_backfill_complete` flag in `paired_relay`.

### Pull flow / reachability

In `lib/sync/peer_reachability_monitor.dart`:

```dart
static const List<PeerTransport> _priority = [
  PeerTransport.lan,
  PeerTransport.relay,
  PeerTransport.tor,
];
```

`_candidateUrl()` gains a `relay` branch that pulls the Follow's Connection card and finds the `Endpoint(type: 'relay')`. Probe via the existing `GET /status` over the Tor SOCKS5 client. `_init()` gets a third map entry. No `sync_engine.dart` change — it's transport-blind via `bestConnectionFor()`.

Ordering means LAN > Relay (fast, always up) > direct onion (slow, may be off).

### Relay HTTP server

`StarlingHttpServer` gains `mode: RelayMode | SocialMode`. Relay mode mounts:

| Endpoint | Handler | Auth | Notes |
|---|---|---|---|
| `GET /status` | reuse `status_handler.dart` | none | returns `{pubkey: paired_owner.pubkey, version, storage_used, event_count}` |
| `GET /manifest` | reuse `manifest_handler.dart` | none | unchanged |
| `GET /events` | reuse `events_handler.dart` | none | unchanged |
| `GET /media/<hash>` | reuse `media_handler.dart` | none | unchanged |
| `POST /events` | new `relay_events_push_handler.dart` | Ed25519 sig | stores raw `EncryptedEvent` blobs; **does NOT decrypt** (zero-knowledge) |
| `POST /media` | new `relay_media_push_handler.dart` | Ed25519 sig | writes blob to `media/<hash[0:2]>/<hash[2:4]>/<hash>` |
| `POST /follow-request` | reuse `follow_request_handler.dart` | none | Relay queues for Owner pickup on next sync |
| `POST /pair` | new `relay_pair_handler.dart` | token + sig | see Pairing handshake |

New middleware `lib/server/middleware/owner_signature_middleware.dart` — reads `X-Starling-Pubkey` + `X-Starling-Sig`, computes `blake2b_256(body)`, verifies via `SodiumCryptoService.verify`, checks pubkey == `relay_paired_owner.pubkey`. 401 on bad sig, 403 on pubkey mismatch.

Existing `rate_limit.dart` middleware applies to all routes; bump Relay default to 360/min for backfill.

The Relay's events-push handler differs from the social `events_push_handler.dart` in one critical way: it does NOT call `contentKey.decryptEvent`. It writes the `EncryptedEvent` bytes verbatim to `served_events`. **Zero-knowledge is structural — the Relay literally has no Feed key.**

### Relay storage

New drift tables (always present in the schema; unused in social mode keeps migration simple):

- `relay_paired_owner(pubkey, bound_at)` — singleton
- `relay_pairing(token, created_at, expires_at, consumed_at)` — singleton
- `served_events(pubkey, created_at, msg_seq, nonce, payload)` — indexed `(pubkey, created_at)`
- `served_media(hash PRIMARY KEY, size, created_at, path)`
- `served_follow_requests` — same columns as `relay-spec.md:152-160`, stored encrypted, Owner picks up on next sync

Retention: retain forever up to a configurable disk cap (default 50% of free space, exposed in the dashboard). On cap-hit, return `507 Insufficient Storage` on writes. Owner-driven pruning UI is Plan 15b.

### Relay dashboard UI

Two screens in `lib/relay/screens/`.

**`relay_pairing_screen.dart` (pre-pair):**
- `StarlingQRCode` rendering `starling-relay://pair?card=…`
- Plaintext onion + 8-char token suffix fallback (reuse `widgets/starling_address_row.dart`)
- Auto-refresh QR when token expires; manual refresh
- Status line flips to dashboard on `/pair` success via Riverpod stream

**`relay_dashboard_screen.dart` (post-pair):**
- Onion address (copyable, monospace)
- Paired Owner pubkey (first 8 + last 4 chars; full on tap)
- Storage: `served_events` count + `served_media` total bytes / cap, `LinearProgressIndicator`
- Last push timestamp
- "Requests in last 24h" — aggregate only (zero-knowledge precludes per-Follower attribution)
- "Unpair" button → confirm → wipes `relay_paired_owner`, `served_events`, `served_media`, `served_follow_requests`, returns to mode picker

### Desktop platform setup

- `flutter create . --platforms=macos,linux,windows` to scaffold runners (`macos/`, `linux/`, `windows/` are absent today)
- No new Dart dependencies; existing packages (`sodium`, `drift` + sqlite3mc, `ffi`, `flutter_secure_storage`, `qr_flutter`, `path_provider`) advertise desktop support
- `lib/main.dart:213` currently gates Arti to `Platform.isIOS || Platform.isAndroid`; enable desktop
- `native/arti_bridge/build.sh` needs `aarch64-apple-darwin` + `x86_64-apple-darwin` targets and a code-signed dylib
- Stub mDNS in Relay mode — Relay is reached via onion; LAN-discovery to/from the Relay is a future optimization

## Files created/modified

**Shared (mode-aware):**
- `lib/main.dart` — read `app_mode`, route to `RelayApp` or `StarlingApp`
- `lib/server/http_server.dart` — `mode` arg, conditional router build
- `lib/services/storage/database.dart` — register new tables
- `lib/utils/connection_card_parser.dart` — recognize `starling-relay://pair`

**Relay-side (new):**
- `lib/relay/relay_app.dart`
- `lib/relay/relay_router.dart`
- `lib/relay/screens/mode_picker_screen.dart`
- `lib/relay/screens/relay_pairing_screen.dart`
- `lib/relay/screens/relay_dashboard_screen.dart`
- `lib/relay/services/pairing_service.dart`
- `lib/relay/services/relay_storage_service.dart`
- `lib/server/handlers/relay_pair_handler.dart`
- `lib/server/handlers/relay_events_push_handler.dart` — raw blob write, NO decrypt
- `lib/server/handlers/relay_media_push_handler.dart`
- `lib/server/middleware/owner_signature_middleware.dart`
- `lib/services/storage/tables/relay_paired_owner_table.dart`
- `lib/services/storage/tables/relay_pairing_table.dart`
- `lib/services/storage/tables/served_events_table.dart`
- `lib/services/storage/tables/served_media_table.dart`
- `lib/services/storage/tables/served_follow_requests_table.dart`
- `lib/services/storage/daos/relay_dao.dart`

**Phone-side (modify or new):**
- `lib/services/lan_network_service.dart` — implement `pushEvents()` / `pushMedia()` with `X-Starling-Sig`
- `lib/services/post_fanout_service.dart` — fan out to `paired_relay` alongside Followers
- `lib/services/relay_pairing_initiator.dart` — phone-side `/pair` POST
- `lib/services/storage/tables/paired_relay_table.dart`
- `lib/services/storage/tables/pending_card_distributions_table.dart` — mirrors `pending_key_distributions_table.dart`
- `lib/server/handlers/manifest_handler.dart` — attach `connection_card_update`
- `lib/sync/peer_reachability_monitor.dart` — add `PeerTransport.relay` to `_priority`, `_candidateUrl`, `_init`
- `lib/sync/outbound_drain.dart` — handle relay-targeted queue rows
- `lib/screens/friends/scan_screen.dart` — branch on `starling-relay://pair`
- `lib/screens/settings/network_settings_screen.dart` — minimal "Set up a relay" entry (full polish in Plan 15b)
- `lib/providers/paired_relay_provider.dart`

**Desktop scaffolding:**
- `macos/`, `linux/`, `windows/` — via `flutter create`
- `native/arti_bridge/build.sh` — extend for desktop targets

**Tests:**
- `test/server/owner_signature_middleware_test.dart`
- `test/server/relay_pair_handler_test.dart`
- `test/server/relay_events_push_handler_test.dart`
- `test/services/relay_pairing_service_test.dart`
- `test/services/post_fanout_relay_test.dart`
- `test/integration/relay_pairing_flow_test.dart`

**Docs:**
- `protocol/plans/protocol-spec.md` — document the new optional `connection_card_update` field on `/manifest`
- `relay/plans/relay-spec.md` — no change (already covers both deployment modes)

## Verification

**End-to-end (manual):**

1. `flutter run -d macos` on a Mac. Mode picker appears. Pick "Run as Relay."
2. Relay boots; Arti bootstraps; `/pair` comes up. QR + plaintext onion appear.
3. On an Android device with an existing identity, open Friends → Scan. Scan the Relay QR. Confirm "Pair this Relay?"
4. Phone POSTs `/pair` over Tor. Relay flips to dashboard; phone writes `paired_relay` and appends the Relay `Endpoint` to its Connection card.
5. Phone publishes a Post. `PostFanoutService` pushes to the Relay. Dashboard shows "Last push: just now"; `served_events` count increments.
6. A second phone (Friend B) follows Phone A via the normal QR flow. On its first `/manifest` to Phone A, it receives `connection_card_update`; its stored card is replaced.
7. Force-quit Phone A.
8. Friend B pull-to-refreshes. `PeerReachabilityMonitor` probes LAN (fail), then Relay (success over Tor), then would-be direct onion (skipped). `/events` fetched from the Relay; decrypts under Phone A's Feed key; Post renders.
9. Friend B fetches a media blob from the Relay; same path; renders.
10. Tap "Unpair" on Relay. Confirms wipe.

**Auth invariants (unit / integration):**
- POST `/events` without `X-Starling-Sig` → 401
- POST `/events` with a non-Owner sig → 403
- POST `/pair` after successful pair → 409 (token consumed)
- POST `/pair` after token expiry → 410
- `relay_events_push_handler` never imports `ContentKeyService` (compile-time enforced)

**Test commands:**
- `cd app/starling && flutter test test/server test/services test/integration`
- `cd app/starling && flutter test integration_test/relay_pairing_flow_test.dart` (run against `flutter test -d macos` and a connected Android device, or two emulators)

## Key decisions

- **Mode is a runtime selection, not a build flavor.** Same binary, same `pubspec.yaml`; the mode picker writes `app_mode` to the keychain and reboots into the appropriate shell on next frame.
- **Mode picker is desktop-only.** Mobile builds always boot social. Reinforces "don't use phones for this" and keeps the mobile binary lean.
- **Pairing token is single-use and bound to the Relay's onion.** Capturing the token doesn't let an attacker redirect the pairing to a Relay they control.
- **Card updates piggyback on `/manifest`.** Reuses Plan 13's distribution pattern; existing Followers don't have to re-scan.
- **The Relay never decrypts.** No Feed key on the Relay; the events-push handler structurally cannot call `contentKey.decryptEvent`.
- **One paired Relay per Owner.** Multi-Relay redundancy is out of scope.

## Risks

- **Arti FFI on desktop** is untested. `native/arti_bridge/build.sh` is set up for iOS/Android cross-compilation only. Adding `aarch64-apple-darwin` + `x86_64-apple-darwin` is the obvious first step; code-signing the dylib for distribution comes later.
- **sqlite3mc compilation on desktop** — drift's `user_defines` hook needs to compile on the host platform on first run. Verify on a clean macOS install before declaring victory.
- **libsodium on Linux/Windows** — the `sodium` package's prebuilt fetcher has historically been flakiest on Windows. Test early.
- **`flutter_secure_storage` on Linux** — needs `libsecret`. Document the dependency in the README; ship a sane error message if missing.
- **mDNS on desktop** — existing `MdnsService` uses iOS/Android platform channels. Stubbed in Relay mode (Relay is reached via onion); revisit if/when LAN discovery between phone and Relay becomes a UX priority.
- **No iOS or mobile relay** — the entire premise of this rework. Strictly enforced by gating the mode picker on `Platform.isMacOS || Platform.isLinux || Platform.isWindows`.

## Out of scope

- **Standalone Rust relay binary** — Plan 15c. Same wire protocol, different implementation.
- **Settings screen polish** (6-row layout, About, network/storage subscreens, manifesto footnote) — Plan 15b.
- **Spare-phone Relay** — abandoned.
- **mDNS discovery of the Relay on LAN** — future optimization.
- **Per-Follower request attribution on the Relay dashboard** — incompatible with zero-knowledge; aggregate counts only.
- **Owner-driven media pruning UI on the Relay** — Plan 15b.
- **Multi-Relay redundancy** — one paired Relay per Owner for v1.
- **Relay-to-Relay gossip** — explicitly not a feature; the Relay only talks to its Owner and that Owner's Followers.
