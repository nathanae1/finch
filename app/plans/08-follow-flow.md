# Plan 08: Follow Flow (QR Scan, Invite Links, Handshake)

## Dependencies
Plan 03 (crypto — key exchange), Plan 04 (identity — connection card), Plan 07 (HTTP server — /follow-request endpoint)

## Scope

The complete follow lifecycle: discover → request → accept → connected.

### QR code scanning
- `mobile_scanner` package for camera-based QR scanning
- Parse scanned data: extract `finch://connect?card={base64url}` URL
- Decode base64url → JSON → ConnectionCard model
- Validate: pubkey present, at least one endpoint

### Deep link handling
- Register `finch://` custom URL scheme on both platforms
- `finch://connect?card={base64url}` → parse connection card → initiate follow
- Use `app_links` package for cross-platform deep link handling
- iOS: Info.plist URL scheme registration
- Android: AndroidManifest.xml intent filter

### Follow request (outbound)
1. Parse connection card from QR/link
2. Derive X25519 keys from own Ed25519 identity
3. Derive shared key via X25519 DH with target's pubkey
4. Encrypt own return endpoints (connection card) with shared key
5. Send `POST /follow-request` to target's endpoint:
   ```
   { requester_pubkey, encrypted_return_endpoints, nonce }
   ```
6. Store in `outbound_follow_requests` table with status=pending

### Follow request (inbound) — UI
- List of pending inbound follow requests (from `inbound_follow_requests` table)
- Each shows: requester pubkey (short form), timestamp
- Accept / Reject buttons

### Accept flow
1. Decrypt requester's return endpoints using X25519 DH shared key
2. Encrypt own feed key for the requester using the same shared key
3. Send `POST /follow-accept` to requester's endpoint:
   ```
   { owner_pubkey, encrypted_feed_key, nonce }
   ```
4. Add requester to `follows` table with their connection card
5. Update inbound request status to accepted

### Reject flow
- Delete from `inbound_follow_requests` table
- No response sent to requester (they don't know they were rejected)

### Receiving follow-accept
- Add `/follow-accept` endpoint to the HTTP server
- Body: CBOR `{ owner_pubkey, encrypted_feed_key, nonce }`
- Decrypt feed key using X25519 DH shared key
- Store in `follows` table: pubkey, connection card, feed key
- Update outbound request status to accepted

### Unfollow
- Remove from `follows` table
- In Phase 1 with key rotation (Plan 13): triggers key rotation

### Follow screen UI
- Scan QR button (opens camera scanner)
- Pending outbound requests list
- Pending inbound requests with accept/reject
- Tab or section toggle between outbound and inbound

### Other profile screen (complete)
- Display name, avatar, bio (from latest kind=2 event in cache)
- Grid of their cached posts
- Unfollow button
- Last synced timestamp
- Connection status: "Reachable" / "Last seen: X ago"

## Files created/modified
- `lib/screens/follow/scan_screen.dart`
- `lib/screens/follow/follow_requests_screen.dart`
- `lib/screens/profile/other_profile_screen.dart` (update from stub)
- `lib/services/follow_service.dart` — handshake logic, key exchange
- `lib/providers/follow_provider.dart` — follows list
- `lib/providers/follow_requests_provider.dart` — pending requests
- `lib/models/follow_request.dart`
- `lib/utils/deep_link_handler.dart`
- `lib/utils/connection_card_parser.dart`
- `lib/server/handlers/follow_accept_handler.dart` — new endpoint
- `lib/server/http_server.dart` (update: add /follow-accept route)
- `ios/Runner/Info.plist` (update: URL scheme)
- `android/app/src/main/AndroidManifest.xml` (update: intent filter)
- `pubspec.yaml` (add `app_links`)
- `test/services/follow_service_test.dart` — full handshake with two mock identities

## Verification
- Scan QR code → connection card parsed correctly, shows confirmation
- Tap invite link → app opens, connection card parsed
- Follow request sent to target's /follow-request → 202 response
- Target sees inbound request in UI
- Accept: feed key encrypted, sent to requester's /follow-accept, received and decrypted
- Requester now has target's feed key in `follows` table — verified by decrypting a test event
- Reject: request removed from UI, no side effects
- Unfollow: removed from follows table
- Full round-trip test: Alice follows Bob (QR scan), Bob accepts, Alice has Bob's feed key, Bob has Alice in followers
- Invalid QR code → error message, not crash

## Key decisions
- Custom URL scheme (`finch://`) for MVP. Universal Links / App Links can be added later for `https://finch.link/connect` URLs.
- Follow-accept is pushed to the requester's endpoint, which requires the requester to be running their HTTP server. If requester is offline, queue the accept and retry later (add to outbound_queue).
- Mutual follows require both sides to initiate independently. Following someone doesn't automatically follow you back.

## Risks
- Camera permission for QR scanning. Handle denial with explanation and manual entry fallback (paste invite link).
- The handshake requires both parties to have reachable servers. In Plan 08, this means LAN only (both on same WiFi). Tor (Plan 11) extends reach to WAN. Document this limitation clearly.
- Deep link handling differs significantly between iOS and Android. `app_links` package smooths this but test thoroughly on both platforms.
- If the requester goes offline between sending the request and receiving the accept, the accept is lost. The outbound queue handles retry, but the UX should show "Pending" clearly.
