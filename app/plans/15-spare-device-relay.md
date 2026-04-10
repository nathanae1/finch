# Plan 15: Spare-Device Relay & Settings Polish

## Dependencies
Plan 07 (HTTP server), Plan 11 (Tor), Plan 14 (foreground service for relay persistence)

## Scope

Turn any spare device into a personal always-on relay. Polish the settings screen to complete the app.

### Relay mode
A mode toggle that converts the app into a dedicated relay. The device:
- Runs the HTTP server 24/7 via foreground service
- Runs Tor onion service (reachable by followers)
- Stores owner's encrypted content pushed from main phone
- Serves content to owner's followers
- Shows minimal dashboard instead of the full app UI

### Pairing flow

**Main phone (relay setup):**
1. Settings → "Set Up Relay" → generates pairing QR code
2. QR contains: `{ owner_pubkey, auth_token, return_endpoints }`
3. `auth_token` is a one-time token for initial pairing
4. After pairing, all future auth uses Ed25519 signature verification

**Spare device (relay setup):**
1. Fresh install of Finch → "Run as Relay" option on welcome screen
2. Scan pairing QR from main phone
3. Receive owner pubkey and auth token
4. Start Tor onion service → get .onion address
5. Report .onion address back to main phone:
   - If on same LAN: via mDNS discovery + HTTP POST
   - If not: via Tor using main phone's onion address from return_endpoints
6. Enter relay mode: show dashboard, start foreground service

**Main phone (after pairing):**
1. Receive relay's .onion address
2. Update connection card: add relay endpoint
3. Begin pushing content to relay

### Relay push (main phone → relay)
- `POST /events` — push new encrypted events to relay
- `POST /media` — push encrypted media blobs to relay
- Auth: `X-Finch-Sig` header (Ed25519 signature of request body hash)
- Push happens:
  - Immediately after creating a new post (if relay reachable)
  - On app open (catch up any posts created while relay was unreachable)
  - Bulk push of all historical own content on initial pairing

### Auth middleware (relay side)
- Verify `X-Finch-Pubkey` matches configured owner pubkey
- Verify `X-Finch-Sig` is valid Ed25519 signature of `sha256(request_body)`
- Reject all unauthorized writes
- Read endpoints (GET) remain unauthenticated (same as on-device server)

### Relay dashboard UI
When in relay mode, the app shows:
- Storage used / available
- Last push received (timestamp)
- Connection status: "Connected to owner" / "Waiting for owner"
- Tor status: .onion address, circuit count
- Event count stored
- "Stop Relay" button → exits relay mode, returns to normal Finch (identity cleared, fresh start)

### Storage on relay
- Same SQLite schema as the on-device server's events/media tables
- Configurable storage limit (default: 50% of available device storage)
- When limit reached: POST /events and POST /media return 507
- Owner can prune oldest media via main phone (future feature, not MVP)

### Settings screen polish (main phone)
Complete the settings screen with all sections:
- **Recovery phrase**: re-display all 24 words (with confirmation prompt for security)
- **Relay configuration**: if paired, show relay status (.onion address, last push, storage used). If not, show "Set Up Relay" button.
- **Storage management**: link to storage settings screen (Plan 12)
- **Tor status**: on/off, .onion address, bootstrap status
- **Network status**: link to network status screen (Plan 14)
- **About**: app version, protocol version, "Made with Finch" link

## Files created/modified
- `lib/screens/relay/relay_dashboard_screen.dart`
- `lib/screens/relay/relay_setup_screen.dart` (main phone side)
- `lib/screens/relay/relay_pairing_screen.dart` (spare device side)
- `lib/services/relay_service.dart` — push logic, pairing, status
- `lib/server/middleware/auth_middleware.dart` — Ed25519 signature verification
- `lib/server/handlers/events_push_handler.dart` (update: relay write path with auth)
- `lib/server/handlers/media_push_handler.dart`
- `lib/screens/settings/settings_screen.dart` (complete)
- `lib/screens/settings/recovery_phrase_screen.dart`
- `lib/screens/settings/relay_settings_screen.dart`
- `lib/router.dart` (update: relay mode routing, settings sub-screens)
- `lib/providers/relay_provider.dart`
- `test/services/relay_service_test.dart`
- `test/server/auth_middleware_test.dart`

## Verification

**Pairing:**
1. Main phone: open relay setup → QR code appears
2. Spare device (Android): fresh install → "Run as Relay" → scan QR
3. Spare device starts Tor, reports .onion address
4. Main phone receives relay address, connection card updated

**Content push:**
5. Main phone: create a post → post pushed to relay
6. Main phone: verify relay received the post (check via relay dashboard or /status endpoint)

**Follower access:**
7. Follower device (not on same LAN as main phone): main phone is OFF
8. Follower pull-to-refresh → content fetched from relay (via Tor)
9. Post displays correctly — relay served the encrypted content

**Settings:**
10. Recovery phrase re-displays correctly
11. Relay settings show accurate status
12. All settings sections present and functional

**Additional:**
- Auth: unauthorized POST to relay → rejected (403)
- Storage limit: fill relay to limit → 507 on next push
- Stop relay: exits relay mode, device returns to welcome screen
- Foreground service: relay stays alive when device is backgrounded (Android)

## Key decisions
- One-time auth token for initial pairing, then Ed25519 signature for ongoing auth. The token is only used during the QR scan handshake.
- Backfill all own content on initial pairing (not just new content). The relay should be a complete mirror.
- iOS relay: extremely limited due to background restrictions. The dashboard works but the relay can't persist in background. Strongly recommend Android for relay duty. Show a warning if running relay mode on iOS.
- "Stop Relay" clears the relay identity and returns to welcome screen. The device can be reused as a normal Finch client.

## Risks
- Relay pairing requires the spare device to report its .onion address back to the main phone. If both are on the same LAN, this is easy (mDNS). If not, the spare device needs to connect to the main phone's onion service — which requires the main phone to be running Tor. Handle the case where neither LAN nor Tor is available: show manual entry (paste .onion address).
- Initial content backfill to relay could be large (hundreds of MB of media). Show progress indicator. Handle interruption (resume where left off).
- Spare device storage varies widely. The 50% default may be too aggressive for a 16GB device or too conservative for a 128GB device. Show actual numbers in the UI.
- iOS relay is functionally useless due to background restrictions. Be upfront: "Relay mode requires Android."
