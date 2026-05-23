# Plan 04: Identity & Onboarding

## Dependencies
Plan 02 (storage service), Plan 03 (crypto service), Plan 04a (design system, app shell, shared components)

## Scope

First-launch experience: generate identity, create profile, back up recovery phrase. Also: restore an existing identity from a recovery phrase.

### Identity generation
- Triggered on first launch when no identity exists in DB
- CryptoService generates Ed25519 keypair + feed key synchronously during the Setup step (sub-100ms on modern devices — no dedicated keygen screen is needed, generation happens as the user taps "Continue")
- Private key → OS keychain
- Public key, feed key, `feed_key_epoch=0`, created_at → identity table in DB
- Recovery phrase derived from seed, shown on the next screen

### Onboarding UI flow (3 steps)
Per the design mockup, onboarding collapses to three screens. No separate keygen animation; no confirm-backup step. Trust the user to write the phrase down.

1. **Welcome screen** — logo + headline "A social feed for your real friends." + subhead "No ads. No algorithm. You own everything. Your posts live on your phone, not a company's server." + primary "Get started" button. Below the button, a secondary link: "Already have an account? Restore from recovery phrase" — taps into the Restore flow (see below).
2. **Setup screen** — single screen that combines profile creation with silent keygen.
   - Display name (required, defaults to empty; "Sam" placeholder only in design)
   - Avatar (optional): tap to open image picker, compress to max 256x256 JPEG, store as encrypted media. A small camera badge overlays the avatar circle as the affordance.
   - "Continue" button (disabled until name is non-empty). On tap: generate Ed25519 keypair + feed key, write identity row, persist secret key to keychain, then advance.
3. **Recovery phrase screen** — all **24 words** in a two-column grid with mono numbering, on a `linen` background.
   - Headline "Your recovery phrase" + body "Write this down. It's the only way to recover your account — there is no server that knows who you are."
   - Small-caption footnote: "Don't screenshot. Don't type it into anything connected to the internet. A piece of paper in a drawer is safer than any app."
   - "Copy to clipboard" link (for users who insist; they'll paste into a password manager at their own risk)
   - Primary button: "I wrote it down" → navigates to the empty feed

**Note on word count**: the design mockup shows 12 words for visual density. The spec is **24 words** (256-bit entropy, matching the Ed25519 seed size and Plan 03's BIP-39 derivation). The implementation must render 24. Keep the two-column grid; it scales from 12 to 24 cleanly.

**Why no keygen screen**: `crypto_sign_keypair()` completes well under 100ms; an explicit animation screen is theatre. If generation takes longer on some low-end Android devices, surface a spinner inside the "Continue" button rather than a dedicated screen.

**Why no confirm-backup step**: the three-word quiz is high-friction and mostly reassurance theatre — users who will lose their phrase will lose it anyway, and users who wrote it down find the quiz annoying. The written-down warning on the recovery screen does the work.

### Restore flow
Reached via the "Restore from recovery phrase" link on Welcome. Used when:
- User reinstalled the app on the same device
- User is moving to a new phone

Steps:
1. **Restore screen** — 24 input fields (4×6 grid) with autofill-from-password-manager support. Or a single paste box that auto-splits on whitespace into the 24 slots. BIP-39 validation (all words must be in the English word list) runs as the user types.
2. On submit: derive seed → Ed25519 keypair → X25519 conversion → write identity row (with `feed_key_epoch=0`, since the recovery phrase does not carry the current epoch — the user restarts from epoch 0 and learns new epochs via follow-accept pushes). Persist secret key to keychain.
3. Navigate to empty feed.

**What restore does not do**: follows are not recovered (connection cards live only on the original device), and prior posts are not recovered from anywhere (the network has no authoritative copy by design). The user starts with an empty feed and has to re-add friends. A small informational banner on the first post-restore feed render sets this expectation clearly: "Welcome back. Re-add your friends to see their posts — Starling only stores content on your phone, so there's nothing to restore from the network."

### Profile as event
- Profile data stored as a kind=2 event: `{ name, bio, avatar_hash }`
- Signed and encrypted with own feed key (same as any other event)
- Updated whenever user changes their profile

### Connection card
- Generated after identity creation: `{ pubkey, endpoints: [], capabilities: ["pairwise-v1"] }`
- Endpoints initially empty (onion address added in Plan 11, relay in Plan 15)
- Capabilities defaults to `["pairwise-v1"]` for v1 clients; future capabilities added as they ship
- Serialized as JSON, base64url-encoded
- QR code rendered by the shared `QRCode` component from Plan 04a (not `qr_flutter` — see Plan 04a for rationale). The sharing UI itself is a bottom-sheet modal defined in Plan 08 (`QrInviteSheet`).
- Invite link format: `starling://connect?card={base64url}`

### App launch routing
- On launch: check if identity exists in DB
- Exists → enter the tab-shell home (Feed tab)
- Doesn't exist → navigate to onboarding (Welcome)
- Use `go_router` for navigation. The tab-shell route is defined in Plan 04a.

### Identity state
- `identityProvider` — loaded from DB on launch, provides pubkey, connection card
- `profileProvider` — loaded from latest kind=2 event, provides name, bio, avatar

### Plan 03 handoff — feed key epoch + real ContentKeyService wiring
Plan 03 landed the crypto primitives but deliberately deferred the storage
and wiring pieces that require a real identity. This plan picks them up:

- **Schema**: Add `feed_key_epoch` column (integer, default 0) to
  `IdentityEntries` and `FollowEntries` tables. Bump drift `schemaVersion`
  to 3 and write the `ALTER TABLE ... ADD COLUMN` migration in
  `database.dart`'s `onUpgrade`.
- **Converters**: Update `identityFromRow`/`identityToCompanion` and
  `followFromRow`/`followToCompanion` in `converters.dart` to carry the
  new field.
- **Types**: Add `int feedKeyEpoch` (default 0) to `Identity` and `Follow`
  in `services/types.dart`.
- **Cache hydration**: In `main.dart`, after the identity is loaded from
  storage, construct a `FeedKeyCache` and populate it with the own
  identity's `(feedKey, feedKeyEpoch)` plus every active follow's
  `(feedKey, feedKeyEpoch)`. Clear the cache on app terminate.
- **Secret key**: Load the Ed25519 secret key from
  `FlutterSecureStorage` (stored during onboarding) and pass it to the
  `PairwiseContentKeyService` constructor.
- **Provider wiring**: Override `contentKeyServiceProvider` with the real
  `PairwiseContentKeyService` in `main.dart`'s `ProviderScope.overrides`
  once identity exists. Fall back to `MockContentKeyService` when
  identity is missing (pre-onboarding) so the app can still boot.
- **Onboarding write**: The keygen step must persist both the identity
  (with `feedKeyEpoch = 0`) and the secret key to secure storage before
  navigating away.

## Files created/modified
- `lib/screens/onboarding/welcome_screen.dart`
- `lib/screens/onboarding/setup_screen.dart` — combined name + avatar + silent keygen
- `lib/screens/onboarding/recovery_phrase_screen.dart`
- `lib/screens/onboarding/restore_screen.dart` — 24-word entry, BIP-39 validation
- `lib/providers/identity_provider.dart`
- `lib/providers/profile_provider.dart`
- `lib/models/identity.dart`
- `lib/models/profile.dart`
- `lib/router.dart` — go_router configuration (onboarding routes; the tab-shell route lives in Plan 04a)
- `pubspec.yaml` (add `go_router`)
- `lib/services/types.dart` (add `feedKeyEpoch` to `Identity` and `Follow`)
- `lib/services/storage/tables/identity_table.dart` (add `feedKeyEpoch` column)
- `lib/services/storage/tables/follows_table.dart` (add `feedKeyEpoch` column)
- `lib/services/storage/database.dart` (bump `schemaVersion` to 3 + migration)
- `lib/services/storage/converters.dart` (update identity/follow converters)
- `lib/main.dart` (hydrate `FeedKeyCache`, wire real `PairwiseContentKeyService`)
- `test/screens/onboarding/` — widget tests with mock services, including the restore path

## Verification
- Fresh install: full 3-step onboarding flow completes, identity in DB, private key in keychain
- Recovery screen renders **24 words** (not 12) in the two-column grid
- Recovery phrase: write down phrase, re-derive keypair from phrase — matches stored keypair
- Profile event: kind=2 event in events table, correctly signed and encrypted
- Connection card: QR code scannable, contains valid base64url-encoded JSON with pubkey
- Invite link: valid `starling://connect?card=...` URL
- Re-launch: onboarding skipped, goes directly to the Feed tab
- Avatar: picked image compressed to ≤256x256, stored as encrypted media
- Restore: entering the 24 words from a fresh-install identity on a second instance produces matching keypair, writes identity row, lands on empty feed
- Restore: non-BIP-39 word rejected inline, "Restore" button stays disabled until all 24 slots contain valid words
- Restore: informational banner about re-adding friends appears on first post-restore feed render

## Key decisions
- `go_router` for navigation (first-party Flutter package, simpler than `auto_route`)
- Avatar max 256x256 JPEG — small enough for QR-adjacent display, large enough to look decent
- Recovery phrase re-display available later in Settings (Plan 15)
- 24 words (not 12). Matches Ed25519 seed size and Plan 03's derivation. The design mockup shows 12 for visual density only; render 24 in the real app.
- No separate keygen screen. Silent keygen during the Setup "Continue" tap; a button-local spinner covers the edge case of slow devices.
- No confirm-backup quiz. The on-screen "write this down" warning carries the weight. Users who will lose their phrase will lose it regardless; the quiz is mostly friction.
- Restore is the secondary path from Welcome, not a third top-level branch. Makes the happy path (first-time user) dominate.

## Risks
- Image picker permissions (camera, gallery) differ by platform. Handle denial gracefully with explanatory message.
- Users will screenshot the recovery phrase. This puts it in iCloud/Google Photos. Acknowledged trade-off — we can't prevent screenshots, only advise against them.
- Restore expectations: users may expect their old posts and friends to come back. The post-restore banner must be loud and clear about what doesn't come back, or we'll get negative reviews from people who feel misled.
- Dropping the confirm-backup step is a real trade-off against users who tap through quickly. Monitor support reports after launch; if a meaningful fraction of users lose access because they didn't actually write down the phrase, reintroduce a low-friction reminder (not a quiz) — e.g., a "verify backup" nudge 24h after onboarding.
