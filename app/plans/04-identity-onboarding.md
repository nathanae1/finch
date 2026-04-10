# Plan 04: Identity & Onboarding

## Dependencies
Plan 02 (storage service), Plan 03 (crypto service)

## Scope

First-launch experience: generate identity, create profile, back up recovery phrase.

### Identity generation
- On first launch: CryptoService generates Ed25519 keypair + feed key
- Private key → OS keychain
- Public key, feed key, created_at → identity table in DB
- Recovery phrase derived from seed, shown to user

### Onboarding UI flow
1. **Welcome screen** — "A social feed for your real friends. No ads. No algorithm. You own everything." + "Get Started" button
2. **Keygen screen** — brief animation while keypair generates (takes <1s, but animation makes it feel intentional)
3. **Profile setup** — display name (required), avatar (optional). Avatar: image picker, compress to max 256x256 JPEG, store as media
4. **Recovery phrase** — show all 24 words clearly. "Write this down. It's the only way to recover your account."
5. **Confirm backup** — re-enter 3 randomly selected words from the phrase
6. **Done** — navigate to empty feed with "Add a friend to get started" + show QR/invite link

### Profile as event
- Profile data stored as a kind=2 event: `{ name, bio, avatar_hash }`
- Signed and encrypted with own feed key (same as any other event)
- Updated whenever user changes their profile

### Connection card
- Generated after identity creation: `{ pubkey, endpoints: [] }`
- Endpoints initially empty (onion address added in Plan 11, relay in Plan 15)
- Serialized as JSON, base64url-encoded
- QR code generated via `qr_flutter`
- Invite link format: `finch://connect?card={base64url}`

### App launch routing
- On launch: check if identity exists in DB
- Exists → navigate to feed
- Doesn't exist → navigate to onboarding
- Use `go_router` for navigation

### Identity state
- `identityProvider` — loaded from DB on launch, provides pubkey, connection card
- `profileProvider` — loaded from latest kind=2 event, provides name, bio, avatar

## Files created/modified
- `lib/screens/onboarding/welcome_screen.dart`
- `lib/screens/onboarding/keygen_screen.dart`
- `lib/screens/onboarding/profile_setup_screen.dart`
- `lib/screens/onboarding/recovery_phrase_screen.dart`
- `lib/screens/onboarding/confirm_backup_screen.dart`
- `lib/providers/identity_provider.dart`
- `lib/providers/profile_provider.dart`
- `lib/models/identity.dart`
- `lib/models/profile.dart`
- `lib/widgets/qr_code_card.dart`
- `lib/router.dart` — go_router configuration
- `pubspec.yaml` (add `go_router`)
- `test/screens/onboarding/` — widget tests with mock services

## Verification
- Fresh install: full onboarding flow completes, identity in DB, private key in keychain
- Recovery phrase: write down phrase, re-derive keypair from phrase — matches stored keypair
- Confirm backup: entering wrong words rejects, correct words proceed
- Profile event: kind=2 event in events table, correctly signed and encrypted
- Connection card: QR code scannable, contains valid base64url-encoded JSON with pubkey
- Invite link: valid `finch://connect?card=...` URL
- Re-launch: onboarding skipped, goes directly to feed
- Avatar: picked image compressed to ≤256x256, stored as encrypted media

## Key decisions
- `go_router` for navigation (first-party Flutter package, simpler than `auto_route`)
- Avatar max 256x256 JPEG — small enough for QR-adjacent display, large enough to look decent
- Recovery phrase re-display available later in Settings (Plan 15)
- No "skip backup" option — confirmation is required before proceeding

## Risks
- Image picker permissions (camera, gallery) differ by platform. Handle denial gracefully with explanatory message.
- Users will screenshot the recovery phrase. This puts it in iCloud/Google Photos. Acknowledged trade-off — we can't prevent screenshots, only advise against them.
- If recovery phrase confirmation is too annoying, users will abandon onboarding. Keep it to 3 words, make the UI frictionless.
