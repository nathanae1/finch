# Plan 05: Post Creation & Local Event Storage

## Dependencies
Plan 02 (storage), Plan 03 (crypto), Plan 04 (identity)

## Scope

Create posts with photos and store them locally as encrypted events.

### Compose screen
- Select photo from gallery or capture with camera
- Add caption (text, optional)
- Preview: show photo + caption before posting
- Post button: triggers the full pipeline

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
- `lib/screens/compose/compose_screen.dart`
- `lib/screens/compose/preview_screen.dart`
- `lib/services/post_service.dart` — event creation pipeline
- `lib/services/media_service.dart` — compression, encryption, filesystem storage
- `lib/providers/compose_provider.dart`
- `lib/providers/events_provider.dart`
- `test/services/post_service_test.dart`
- `test/services/media_service_test.dart`

## Verification
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
