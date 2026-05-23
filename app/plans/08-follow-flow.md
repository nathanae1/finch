# Plan 08: Follow Flow (QR Scan, Invite Links, Handshake)

## Dependencies
Plan 03 (crypto — key exchange), Plan 04 (identity — connection card), Plan 04a (design system, shell, `Sheet` component), Plan 07 (HTTP server — /follow-request endpoint)

## Scope

The complete follow lifecycle: discover → request → accept → connected. Plus the Friends tab as a primary destination in the app shell.

### QR code scanning
Starling ships its own native QR scanner on both platforms. **No `mobile_scanner`, no Google ML Kit, no Google Play Services dependency.** Two independent reasons:

1. **Product/privacy**: Google ML Kit on Android pulls in Google Play Services, which means Google gets a signal every time Starling is installed and has a runtime dep on Google's stack. For a product positioned as "no servers, no corporations, you own everything," that's a tonal mismatch — we shouldn't need Google to turn on the camera.
2. **Developer experience**: Google ML Kit's iOS pods don't ship arm64-simulator slices. On Apple Silicon Macs running native arm64 iOS simulators, any project that imports `mobile_scanner` fails to install — the whole simulator dev loop for QR-related flows is gated behind running the sim under Rosetta. That's a non-starter for iteration.

QR decoding is a solved, built-in capability on both platforms. We don't need the heavyweight barcode detector.

**iOS: AVFoundation platform channel (~50 LOC Swift)**
- `AVCaptureSession` with the back camera input
- `AVCaptureMetadataOutput` with `metadataObjectTypes = [.qr]`
- `AVCaptureVideoPreviewLayer` for the live preview
- Delegate callback fires on QR detection with the decoded string
- Present as a `UIViewController` hosted via `FlutterPlatformView`
- Handle camera permissions via `AVCaptureDevice.requestAccess(for: .video)`
- Minimum iOS: 26 (matches project target; AVFoundation QR support has been in since iOS 7, but we don't care about legacy)

**Android: CameraX + ZXing (or the Play-Services-free variant)**
- `androidx.camera:camera-core` / `camera-camera2` / `camera-view` (AndroidX, not GMS)
- `com.google.zxing:core` (pure Java, permissively licensed, not tied to Google Play Services despite the `com.google.zxing` namespace — the package is just a historical artifact of its origin)
- `ImageAnalysis` analyzer pipes frames into `MultiFormatReader.decode` filtered to `BarcodeFormat.QR_CODE`
- Hosted via Flutter's `PlatformView` for Android
- Handle camera permission via `ActivityCompat.requestPermissions`
- Minimum Android: API 26 (matches project target)

**Flutter-side contract**
A single `QrScannerChannel` method-channel-backed service:
- `Future<void> start()` — requests camera permission, starts capture
- `Stream<String> get scans` — emits decoded payloads
- `Future<void> stop()` — tears down the capture session
- Errors: `permission-denied`, `camera-unavailable`, `cancelled`

The Flutter widget (`QrScannerView`) wraps `UiKitView` / `AndroidView` and subscribes to the stream. The widget handles UI (reticle overlay, "Point at a Starling QR" copy, paste-invite-link fallback button per Plan 08's earlier spec); the platform channel just wraps the native detector.

**Payload handling**
Parse scanned data: extract `starling://connect?card={base64url}` URL. Decode base64url → JSON → `ConnectionCard` model. Validate: pubkey present, at least one endpoint. Invalid payloads surface an error in the confirm sheet, not a crash.

### Deep link handling
- Register `starling://` custom URL scheme on both platforms
- `starling://connect?card={base64url}` → parse connection card → initiate follow
- Use `app_links` package for cross-platform deep link handling
- iOS: Info.plist URL scheme registration
- Android: AndroidManifest.xml intent filter

### Follow request (outbound)
1. Parse connection card from QR/link (including `capabilities` field)
2. Derive X25519 keys from own Ed25519 identity (CryptoService)
3. Derive shared key via X25519 DH with target's pubkey (CryptoService)
4. Encrypt own return endpoints (connection card) with shared key (CryptoService)
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
1. Decrypt requester's return endpoints using X25519 DH shared key (CryptoService)
2. Encrypt own feed key for the requester using the same shared key (ContentKeyService)
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

### Friends tab (primary screen)
The Friends tab renders `FriendsScreen`, which is the friends list itself — not a request-manager. This matches the Claude Design mockup.

- **Header**: `TopBar` with title "Friends" and a right-slot `+` `IconButton` that opens `QrInviteSheet` (see below). No back button — this is a tab root.
- **"Add a friend" card** pinned at top of the scroll view: linen background, hairline border, radius 14, with a qr-code icon in a sage-soft rounded tile on the left, "Add a friend" / "Scan their QR, or share yours." on the center, and a **PrimaryButton** "Open" on the right. Tapping the card or the button opens `QrInviteSheet`.
- **Section header**: a `starling-micro` "N friends" label below the card.
- **Friend rows**: one per follow, separated by hairline borders. Each row:
  - `Avatar md` (36) with the friend's color
  - Display name in 15 ink
  - Status below the name: "● Reachable" in success-green when the peer responded recently, or "Last seen 2h" / "Last seen 3d" (humanized relative) in stone otherwise
  - Right-slot dots-three `IconButton` that opens a per-friend action menu (at minimum: "View profile", "Unfollow"). Menu can be a small bottom sheet using `Sheet`.
- Pending inbound follow requests surface as a dedicated banner row at the top of the list (above the "Add a friend" card) when any exist: "{Name or short pubkey} wants to follow you" + Accept / Reject buttons inline. Multiple requests stack. When none, the banner is absent.
- Pending outbound requests appear inline in the list with a muted appearance and a "Pending" label where the status would be.

### Scan screen
Full-screen camera view, pushed as a modal over the Friends tab (or from the Restore / onboarding flows if needed). Not a sheet — we need the whole viewport for the camera preview.

- Uses `mobile_scanner` for the camera feed
- Overlay: a centered square reticle with a hairline border, dimmed surround, and small "Point at a Starling QR" copy
- A **GhostButton** "Paste invite link" at the bottom falls back to `starling://connect?card=...` text entry if the camera is denied or the user prefers pasting
- On successful parse: dismisses scan, advances to a confirm sheet showing the requester's pubkey (short form) and a "Send follow request" primary action

### QR invite sheet
Moved from "full-screen QR page" to a bottom-sheet modal. Uses the shared `Sheet` component from Plan 04a.

- **Headline**: "Scan to add me as a friend" in Fraunces 22/500, centered
- **Sub**: "Share this with people you trust. There's no way for strangers to find you." in 13 graphite
- **QR card**: the rendered connection-card QR inside a paper card with hairline border, radius 14, `shadowSoft`. Size ~180px. Built on the `QRCode` component from Plan 04a.
- **Mono link line**: truncated `starling://connect?card=eyJwdWJrZXkiOiJ4NGs…` in IBM Plex Mono 11/stone, word-break break-all
- **Actions row**: **SecondaryButton** "Copy link" (flash to "Copied" for ~1.4s on tap) + **PrimaryButton** "Done" (closes the sheet)

Opened from:
- The `+` icon in the Friends tab header
- The "Add a friend" card on Friends tab
- "Share invite" button on the "You" tab (Plan 06)
- Any future empty-state CTA that wants to prompt an invite

### Other profile screen (complete)
- Display name, avatar, bio (from latest kind=2 event in cache)
- Grid of their cached posts (3-column, matching Plan 06's own-profile grid)
- Unfollow button
- Last synced timestamp
- Connection status: "Reachable" / "Last seen: X ago" (same string convention as the friends list)

## Files created/modified
- `lib/screens/friends/friends_screen.dart` — primary Friends tab (list, "Add a friend" card, pending banners, action menu)
- `lib/screens/friends/scan_screen.dart` — camera QR scan + paste-link fallback
- `lib/screens/friends/confirm_request_sheet.dart` — post-scan confirmation (`Sheet`)
- `lib/screens/friends/friend_actions_sheet.dart` — dots-three per-friend menu (`Sheet`)
- `lib/widgets/qr_invite_sheet.dart` — bottom-sheet invite UI (headline, QR card, mono link, Copy/Done)
- `lib/screens/profile/other_profile_screen.dart` (update from stub)
- `lib/services/follow_service.dart` — handshake logic, key exchange
- `lib/providers/follow_provider.dart` — follows list
- `lib/providers/follow_requests_provider.dart` — pending requests (inbound + outbound)
- `lib/models/follow_request.dart`
- `lib/utils/deep_link_handler.dart`
- `lib/utils/connection_card_parser.dart`
- `lib/utils/time_ago.dart` — shared "2h" / "3d" / "now" humanizer used by friends list and post cards
- `lib/server/handlers/follow_accept_handler.dart` — new endpoint
- `lib/server/http_server.dart` (update: add /follow-accept route)
- `lib/router.dart` (update: register `/friends` tab route under Plan 04a's shell, plus `/friends/scan` modal)
- `ios/Runner/Info.plist` (update: URL scheme)
- `android/app/src/main/AndroidManifest.xml` (update: intent filter)
- `pubspec.yaml` (add `app_links`; do **not** add `mobile_scanner` — see QR scanning section)
- `lib/services/qr_scanner_service.dart` — Dart-side service wrapping the method channel (`start` / `scans` stream / `stop`)
- `ios/Runner/QrScannerPlugin.swift` — Swift platform channel: `AVCaptureSession` + `AVCaptureMetadataOutput` + `AVCaptureVideoPreviewLayer`
- `ios/Runner/AppDelegate.swift` (update: register the plugin with the engine)
- `ios/Runner/Info.plist` (update: URL scheme **and** `NSCameraUsageDescription`)
- `android/app/src/main/kotlin/dev/starling/app/QrScannerPlugin.kt` — CameraX + ZXing analyzer
- `android/app/src/main/kotlin/dev/starling/app/MainActivity.kt` (update: register the plugin)
- `android/app/src/main/AndroidManifest.xml` (update: intent filter + `android.permission.CAMERA`)
- `android/app/build.gradle` (update: add `androidx.camera:*` + `com.google.zxing:core` deps)
- `test/services/follow_service_test.dart` — full handshake with two mock identities
- `test/screens/friends/friends_screen_test.dart` — renders list, pending banner, card; opens QR sheet from three entry points

## Verification
- Friends tab: `TopBar` "Friends" + right-slot `+` icon renders correctly
- "Add a friend" card renders at the top of the list; tapping it (card or "Open" button) opens `QrInviteSheet`
- `QrInviteSheet`: headline, QR image, mono truncated link, Copy link (shows "Copied" flash) and Done button
- `QrInviteSheet` is opened from Friends `+` icon, "Add a friend" card, and "Share invite" on the "You" tab — all three entry points produce the same sheet
- Friend rows: status renders as "● Reachable" (success-green) or "Last seen Xh" / "Last seen Xd" in stone
- Pending inbound request: banner row appears at top of the list with Accept / Reject
- Accept: feed key encrypted, sent to requester's /follow-accept, received and decrypted; friend row moves from banner into the friends list
- Reject: request removed from UI, no side effects
- Pending outbound request: row shows muted appearance with "Pending" label
- Dots-three on a friend row opens `friend_actions_sheet` with View profile / Unfollow
- Scan QR code → camera view → parse → confirm sheet → "Send follow request" → request sent to target's /follow-request (202)
- Scan: denying camera permission surfaces the "Paste invite link" fallback
- Tap invite link (deep link) → app opens → confirm sheet → request sent
- Requester now has target's feed key in `follows` table — verified by decrypting a test event
- Unfollow: removed from follows table
- Full round-trip test: Alice follows Bob (QR scan), Bob accepts, Alice has Bob's feed key, Bob has Alice in followers
- Invalid QR code → error message in the confirm sheet, not a crash

## Key decisions
- Custom URL scheme (`starling://`) for MVP. Universal Links / App Links can be added later for `https://starling.link/connect` URLs.
- Follow-accept is pushed to the requester's endpoint, which requires the requester to be running their HTTP server. If requester is offline, queue the accept and retry later (add to outbound_queue).
- Mutual follows require both sides to initiate independently. Following someone doesn't automatically follow you back.
- **Friends tab is a list-first screen, not a request-manager.** Pending requests surface as banners in-context. This keeps the happy-path (viewing your friends) dominant and demotes the admin-path (managing requests) to an inline concern.
- **QR invite as a bottom sheet, not a full-screen page.** It's a focused action, not a destination. Using `Sheet` also lets us open it from the Friends tab, the "You" tab, and the empty-feed state with a single widget instance.
- **Full-screen scan, not a sheet.** Camera preview needs the full viewport for framing, and partial-obscuration would invite blurry scans.
- **Bespoke native scanner, not `mobile_scanner`.** Two reasons: (1) Google Play Services dependency on Android breaks the "no Google, no corporations" product posture. (2) Google ML Kit's iOS pods lack arm64-simulator slices, which would force every iOS dev to run the sim under Rosetta for QR flows. AVFoundation on iOS and CameraX+ZXing on Android cover QR decoding without either problem, at a cost of ~50 LOC per platform. ZXing's package namespace (`com.google.zxing`) is a historical artifact from its original hosting; the library itself is pure Java, Apache 2.0, and has no runtime Google dependency.

## Risks
- Camera permission for QR scanning. Handle denial with explanation and manual entry fallback (paste invite link).
- Writing the native scanner ourselves means we own the bugs. Risks: camera-in-use-by-another-app errors, orientation handling, scan-region accuracy, permission UX divergence between iOS and Android. Mitigation: keep the native code small and dumb — it only detects a QR payload and hands the string to Flutter. All UI, retry logic, and error messaging lives in the Dart layer.
- The handshake requires both parties to have reachable servers. In Plan 08, this means LAN only (both on same WiFi). Tor (Plan 11) extends reach to WAN. Document this limitation clearly.
- Deep link handling differs significantly between iOS and Android. `app_links` package smooths this but test thoroughly on both platforms.
- If the requester goes offline between sending the request and receiving the accept, the accept is lost. The outbound queue handles retry, but the UX should show "Pending" clearly.
