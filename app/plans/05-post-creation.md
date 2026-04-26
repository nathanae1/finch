# Plan 05: Post Creation & Local Event Storage

## Dependencies
Plan 02 (storage), Plan 03 (crypto), Plan 04 (identity), Plan 04a (design system, shared components, shell with Compose modal route)

## Scope

Create posts with photos and store them locally as encrypted events.

### Compose screen
Matches the Claude Design mockup layout, with two important deviations noted below.

- **Header**: ✕ (cancel, left), centered "New post" title in Fraunces display 18/500, and a **Ghost** "Post" button on the right (disabled until a photo is selected). Tapping Post advances to the **Preview screen** (it does not publish immediately — see rationale below).
- **Photo area**: an inline, 4:5 dashed placeholder when no photo is chosen. The placeholder shows a camera icon, "Choose a photo" text, and two `SecondaryButton`s labeled **Gallery** and **Camera**. Once a photo is chosen, the placeholder is replaced by the photo itself (rounded 14, hairline border) with a ✕ overlay in the top-right (32px circle, semi-transparent ink background) that clears the selection.
- **Caption**: multi-line `Textarea` below the photo, placeholder "Say something…". Optional.
- **No trust/encryption footnote on the compose screen.** The mockup's earlier "End-to-end encrypted" line was explicitly removed — trust is supposed to be inherent in the product, not performed in microcopy. Do not reintroduce it.

### Preview screen
Kept as a distinct screen (not merged into Compose). The mockup collapses them for visual brevity, but splitting gives the user a clear "final review" step and keeps the publish pipeline behind an explicit commit. Preview renders:
- The chosen photo at full 4:5 aspect with the caption beneath, in the same layout the viewer will see on the feed
- A sticky bottom bar with a **GhostButton** "Back to edit" and a block **PrimaryButton** "Post" that triggers the publish pipeline (step "Event creation" below)
- No header chrome — this is the "what your friends will see" moment

**Why two screens and not one:** the publish pipeline is destructive in the sense that once the event is signed + written, deleting it generates a kind=6 event rather than undoing anything. A preview step matches that weight: edit freely here, commit over there. It also gives us somewhere obvious to add future publish options (cross-post to a second audience, schedule, etc.) without crowding the compose screen.

### Photo pipeline
1. Pick or capture image
2. Compress: max 1080px on longest side, JPEG quality 80
3. Store original (own photos only) + compressed version
4. Compute BLAKE2b-256 hash of plaintext compressed photo
5. Encrypt compressed photo with feed key (random nonce, prepended to blob)
6. Write encrypted blob to app's sandboxed filesystem
7. Register in `media_cache` table: hash, path, size, last_accessed

Use `compute()` or a separate isolate for compression and encryption to avoid UI jank.

### Event creation (kind=1: Post)
Uses the publish pipeline from Plan 03:
1. Build `Event`: version, pubkey, created_at (from `Clock`), kind=1, content=caption, media=[MediaRef(hash, mime_type, size)], extensions={}
2. Compute ID: `blake2b_256(cbor(version + pubkey + created_at + kind + ref + content + media + extensions))`
3. Resolve `Audience.broadcast`
4. `ContentKeyService.encryptForAudience(event, audience)` → signs, encrypts with current feed key, returns `EncryptedEvent`
5. Wrap in `EnvelopeItem(type: "event")` → `Envelope`
6. Store `EncryptedEvent` in events table with `is_own=1`

### Delete event (kind=6)
- Create a kind=6 event with `ref` pointing to the target event ID
- Signed and encrypted like any other event
- UI removes the target event from display
- The original encrypted event remains in storage (followers may have cached it)

### Filesystem layout
```
{app_dir}/media/
  {hash_prefix_2}/{hash_prefix_4}/{full_hash}    # encrypted blobs
```
Hash-prefix sharding prevents too many files in one directory.

### State management
- `composeProvider` — tracks compose state (selected photo, caption, processing status)
- `eventsProvider` — queries own events from DB, provides decrypted list
- Both are Riverpod providers

## Files created/modified
- `lib/screens/compose/compose_screen.dart` — header (✕ / "New post" / Ghost "Post"), inline photo picker placeholder, Gallery/Camera buttons, caption textarea. Reached via the "Post" tab (Plan 04a) which pushes this as a full-screen modal.
- `lib/screens/compose/preview_screen.dart` — full-photo preview with caption, sticky "Back to edit" / "Post" bar. Pushed onto the Compose modal stack.
- `lib/services/post_service.dart` — event creation pipeline
- `lib/services/media_service.dart` — compression, encryption, filesystem storage
- `lib/providers/compose_provider.dart` — holds selected photo + caption across compose → preview
- `lib/providers/events_provider.dart`
- `test/services/post_service_test.dart`
- `test/services/media_service_test.dart`
- `test/screens/compose/` — widget tests for both screens (selection, clear, back-to-edit, preview → post)

## Verification
- Compose modal opens from the "Post" tab over whichever tab is active; dismissing returns to that tab (not always Feed)
- Compose: "Post" button is disabled until a photo is selected
- Compose → Preview: advances with the chosen photo + caption carried through
- Preview → "Back to edit": returns to Compose with selections intact (compose_provider state preserved)
- Preview → "Post": creates the event, closes the modal, lands the user back on whichever tab they were on
- No "end-to-end encrypted" microcopy anywhere on Compose or Preview
- Create a post with photo + caption: event appears in DB
- Event fields: correct kind, pubkey, created_at, media_refs, signature
- `is_own=1` on the stored event
- Encrypted media blob exists on filesystem at expected path
- Decrypt event from DB: plaintext matches original caption
- Decrypt media from filesystem: BLAKE2b-256 hash matches MediaRef.hash
- Delete event: kind=6 created with correct ref, target no longer shown in queries
- Multiple posts: each has unique ID and unique nonce
- Large photo: compression + encryption doesn't block UI (runs in isolate)

## Key decisions
- JPEG quality 80, max 1080px — balance between quality and size. Most photos will be 200-500KB compressed.
- Store both original and compressed for own photos (original for potential future high-res viewing)
- Use `compute()` for heavy operations (compression, encryption) to keep UI responsive
- Hash-prefix sharding for filesystem (matches relay spec's media storage pattern)

## Risks
- Memory pressure from large images. Process one photo at a time, release references after encryption.
- `image` package compression may be slow for large photos. Profile on real devices; consider `flutter_image_compress` as alternative if needed.
- Camera permissions must be handled gracefully on both platforms.
