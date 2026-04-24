# Plan 09: LAN Sync (mDNS Discovery + Manifest Exchange)

## Dependencies
Plan 06 (feed display), Plan 07 (HTTP server), Plan 08 (follow flow — follows exist to sync)

## Scope

This is the convergence plan. Everything before it is building blocks. This is where two devices talk to each other and content flows. **First end-to-end test of the entire system.**

### mDNS service registration
- Register `_finch._tcp` service via `multicast_dns` package
- TXT record includes: `pubkey={short_pubkey}`, `port={server_port}`
- Register on app launch (after server starts)
- Deregister on app terminate

### mDNS discovery
- Scan for `_finch._tcp` services on the local network
- Build peer cache: `Map<String, LanPeer>` where key is pubkey, value is IP:port
- Filter: only care about pubkeys in our follows list
- Rescan on pull-to-refresh and periodically while app is open (every 30s)

### Sync engine
Core orchestration logic, runs on app open and pull-to-refresh.

**Steps:**
1. **Build want list**: for each followed pubkey, determine what events we're missing within the sync window (default 30 days). Query local events table for latest `created_at` per pubkey.
2. **Discover reachable endpoints**: check mDNS cache for LAN peers matching followed pubkeys. (Relay and Tor tiers added in Plans 11, 15.)
3. **Exchange manifests**: for each reachable peer, `GET /manifest?since={last_synced_at}` → get list of event IDs we don't have
4. **Pull missing events**: `GET /events?since={timestamp}` → receive `Envelope` containing `EnvelopeItem`s
5. **Process envelope**: parse Envelope (untrusted container), extract EnvelopeItems, process each by type. For type `"event"`: decrypt EncryptedEvent with the follow's feed key (via ContentKeyService), verify Ed25519 signature, reject invalid events. Unknown item types are preserved and stored for future compatibility.
6. **Store locally**: insert into events table with `is_own=0`, update `last_synced_at` for the follow

### Sync concurrency
- Max 5 parallel peer connections
- Process peers in order of expected speed: LAN first (only tier available in this plan)
- Use `Future.wait` with a concurrency limiter (e.g., pool of 5)

### Deduplication
- Before fetching events, compare manifest against local event IDs
- Skip events already in local DB (by event ID)

### Media lazy loading (from peers)
- Update `EncryptedImage` widget: if media hash not in local cache, fetch from peer
- `GET /media/{hash}` from the author's endpoint
- Decrypt, verify hash, cache locally
- If author offline: show placeholder, retry on next sync

### Sync status
- `syncProvider` — tracks: syncing/idle, last sync time, per-peer status
- UI: sync status indicator on feed screen updates in real-time
- Pull-to-refresh triggers sync and shows spinner

### Error handling
- Peer unreachable: skip, try next peer, mark as unreachable
- Invalid response: skip event, log warning
- Decryption failure: skip event (wrong feed key? corrupted?), log warning
- Network timeout: 10s per request, move on

## Files created/modified
- `lib/sync/sync_engine.dart` — main orchestration
- `lib/sync/manifest_exchange.dart` — manifest fetch and diff
- `lib/sync/peer_connection.dart` — HTTP client wrapper for peer endpoints
- `lib/services/discovery_service.dart` — mDNS registration + scanning
- `lib/providers/sync_provider.dart`
- `lib/providers/discovery_provider.dart`
- `lib/widgets/encrypted_image.dart` (update: fetch from peer if not cached)
- `lib/providers/feed_provider.dart` (update: include synced events in feed)
- `test/sync/sync_engine_test.dart` — with mock peers
- `test/sync/manifest_exchange_test.dart`

## Verification

**This is the most important verification in the entire project:**
1. Two real devices on the same WiFi network
2. Device A: create identity, create a post with photo
3. Device B: create identity, follow Device A (QR scan, accept)
4. Device B: pull-to-refresh → Device A's post appears in feed with photo
5. Device A: create another post → Device B pull-to-refresh → new post appears

**Additional checks:**
- mDNS: `dns-sd -B _finch._tcp` on macOS shows registered services
- Manifest exchange: correct event IDs returned
- Deduplication: re-syncing doesn't create duplicate events
- Media lazy loading: photo loads when post scrolls into view
- Offline peer: shows "Last seen: X" and placeholder for media
- Sync status: indicator updates correctly during sync
- 5+ peers: concurrent sync doesn't crash or corrupt data
- **Test on real hardware** — simulators may not see each other's mDNS

## Key decisions
- mDNS TXT record includes pubkey so we can filter discovered services against our follows list before connecting. Saves unnecessary HTTP connections.
- Sync window: 30 days, hardcoded for MVP. Users can't change it. Keeps scope bounded.
- Sync runs in the main isolate but uses async I/O. If profiling shows jank, move to a dedicated isolate in a later plan.
- Only sync events, not media. Media is lazy-loaded per-post. This keeps sync fast.

## Risks
- mDNS is unreliable on some Android devices and corporate/school networks that block multicast. The app must handle discovery failure gracefully — show "No peers found on this network" rather than hanging.
- LAN sync without TLS: HTTP metadata (request paths, timing) visible to network observers. Content payloads are E2E encrypted. This is the accepted trade-off from the spec.
- Two emulators/simulators on the same machine may not see each other's mDNS. **Test on real physical devices.**
- Race condition: sync and post creation happening simultaneously. Use database transactions for writes.
