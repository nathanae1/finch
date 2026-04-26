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
- `POST /events` — push `Envelope` containing `EnvelopeItem`s to relay. The relay stores items without inspecting payloads (zero-knowledge).
- `POST /media` — push encrypted media blobs to relay
- Auth: `X-Finch-Sig` header (Ed25519 signature of request body hash)
- Push happens:
  - Immediately after creating a new post (if relay reachable)
  - On app open (catch up any posts created while relay was unreachable)
  - Bulk push of all historical own content on initial pairing

### Auth middleware (relay side)
- Verify `X-Finch-Pubkey` matches configured owner pubkey
- Verify `X-Finch-Sig` is valid Ed25519 signature of `blake2b_256(request_body)`
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
The Claude Design mockup groups settings into six top-level rows. This plan adopts that grouping — it's simpler for non-technical users and keeps the technical surface (Tor, relay, network) tucked under a single "Network" row rather than spread across three.

Each row uses the same visual pattern: a rounded `linen` tile with an icon on the left, a two-line label + subtitle in the middle, and a caret-right on the right.

1. **Profile** (icon: `user`) — sub: "Display name, photo, bio". Pushes the profile-edit screen (stubbed in Plan 06 via the "Edit" button; this row is a second entry point).
2. **Recovery phrase** (icon: `key`) — sub: "View or re-export". Pushes a confirmation screen ("Only view this where no one can see your screen.") then re-displays the 24 words on the same `linen` grid used in onboarding.
3. **Notifications** (icon: `bell-slash`) — sub: "Off". **Informational only**, not a toggle. Pushes a read-only screen explaining: "Finch doesn't send notifications — your phone only checks when you open the app. There's no server to push from, so nothing can ping you when you're not looking." No code path writes anything, no push-token handling, no FCM/APNS integration anywhere in the app. This row exists so the absence is explained, not hidden.
4. **Network** (icon: `globe`) — sub: "Local Wi-Fi + Tor". Pushes the network detail screen which subsumes what earlier drafts of this plan had split into three top-level rows:
   - **Local Wi-Fi section**: mDNS discovery status, currently-reachable peer count
   - **Tor section**: bootstrap status, .onion address (with a copy button), circuit count
   - **Relay section**: if paired, show the relay's .onion address, last-push timestamp, storage used on the relay. If not paired, show a **PrimaryButton** "Set Up Relay" that opens the pairing flow (`/relay/setup`).
   Grouping all three under Network matches the user's mental model ("how Finch talks to my friends") rather than the engineer's (Wi-Fi vs. Tor vs. relay as separate subsystems).
5. **Storage** (icon: `download-simple`) — sub: live "N posts · M MB" string. Pushes the storage management screen from Plan 12 (usage breakdown, clear cache, export).
6. **About Finch** (icon: `question`) — sub: "v{app_version}". Pushes a static screen with app version, protocol version, credits, and the one-paragraph manifesto: "Finch doesn't have a server. Your phone talks to your friends' phones directly, through Tor when you're apart and over local Wi-Fi when you're close. Sometimes a post takes a few minutes to show up because your friend's phone was off. That's fine."

Also render the same manifesto paragraph as a small footnote (12 stone) at the bottom of the settings list itself — it's the tone the app opens with, so it should be the tone it closes with too.

## Files created/modified
- `lib/screens/relay/relay_dashboard_screen.dart`
- `lib/screens/relay/relay_setup_screen.dart` (main phone side)
- `lib/screens/relay/relay_pairing_screen.dart` (spare device side)
- `lib/services/relay_service.dart` — push logic, pairing, status
- `lib/server/middleware/auth_middleware.dart` — Ed25519 signature verification
- `lib/server/handlers/events_push_handler.dart` (update: relay write path with auth)
- `lib/server/handlers/media_push_handler.dart`
- `lib/screens/settings/settings_screen.dart` (complete — 6 rows per design grouping, manifesto footnote)
- `lib/screens/settings/profile_edit_screen.dart` — pushed from row 1 (and from "Edit" on the "You" tab)
- `lib/screens/settings/recovery_phrase_screen.dart` — confirmation → re-display
- `lib/screens/settings/notifications_screen.dart` — informational only, no toggle
- `lib/screens/settings/network_screen.dart` — Wi-Fi + Tor + Relay sections inside one screen
- `lib/screens/settings/about_screen.dart` — version, protocol version, manifesto
- `lib/router.dart` (update: relay mode routing, settings sub-screens under the tab shell)
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
10. Settings list renders the 6 rows in order: Profile / Recovery phrase / Notifications / Network / Storage / About Finch
11. Each row shows the correct icon in its linen tile + caret-right affordance
12. Recovery phrase: confirmation prompt gates the re-display, 24 words render correctly
13. Notifications row: pushes an informational screen (no toggle, no switch, no permission prompt); no code path anywhere requests push tokens or registers for remote notifications
14. Network screen: shows Wi-Fi status, Tor bootstrap status + .onion (copyable), and Relay status or "Set Up Relay" button as appropriate
15. Storage row subtitle reflects live values ("N posts · M MB") and the row pushes Plan 12's storage screen
16. About screen: version, protocol version, manifesto paragraph
17. Manifesto footnote renders at the bottom of the main Settings list in 12 stone
18. No push-notification integration is present in the app bundle (verify by grepping for `UNUserNotification`, `FirebaseMessaging`, `APNS`, etc. → zero matches)

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
