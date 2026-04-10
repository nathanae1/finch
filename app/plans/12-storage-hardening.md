# Plan 12: Storage Hardening

## Dependencies
Plan 02 (storage), Plan 03 (crypto), Plan 05 (posts exist), Plan 09 (synced content exists)

## Scope

Audit and harden the storage layer. Verify encryption is actually working. Implement retention enforcement. Add storage management UI.

### Encryption audit
- **SQLCipher verification**: open the raw DB file and confirm it's not readable as plain SQLite. Write a test that tries to open the DB without the key and expects failure.
- **Media files at rest**: verify all files in the media directory are encrypted blobs (not valid JPEG/PNG without decryption). Write a test that reads raw bytes and confirms they're not a valid image header.
- **OS keychain audit**: confirm identity private key and DB encryption key are both stored with correct access control:
  - iOS: `kSecAttrAccessibleAfterFirstUnlock` (available after first unlock, persists across reboots)
  - Android: Keystore with user-authentication not required (app needs access at launch without biometrics)

### Feed key cache lifecycle
- Load all followed accounts' feed keys from DB into memory on app launch
- Clear the in-memory cache on app terminate
- Consider clearing on screen lock (more secure but slower resume). Decision: don't clear on lock for MVP — the DB is already encrypted, and the cache only lives in-process memory.

### Retention enforcement
- Run on app open (once per launch, not repeatedly)
- **Events from others**: delete where `is_own=0 AND created_at < (now - 30 days) AND last_viewed < (now - 7 days)`
  - The `last_viewed` grace period keeps recently-viewed old content alive
- **Media from others**: calculate total size of non-own media in media_cache. If > 2GB, delete oldest by `last_accessed` until under limit. Remove corresponding files from filesystem.
- **Own content**: never touched by retention

### `last_viewed` tracking
- Update `events.last_viewed` when a post scrolls into the viewport
- Debounce: update at most once per post per app session (avoid write storms)
- Used by retention to keep recently-viewed content alive past the 30-day window

### Storage management UI (Settings)
- Total storage used by Finch
- Breakdown: own content vs cached content
- Cache size display (media from others)
- "Clear cache" button: deletes all non-own media files and media_cache entries. Events from others are kept (they're small).
- Confirmation dialog before clearing

### Data export
- Export all own events as a signed CBOR bundle
- Bundle format: `{ pubkey, events: [Event, ...], media: [{ hash, blob }, ...] }`
- Signed with identity key for authenticity
- Saved to a user-chosen location (share sheet)
- This is future-proofing for multi-device import, not a user-facing backup feature yet

## Files created/modified
- `lib/services/storage/retention.dart` (update: full implementation)
- `lib/services/storage/encryption_audit.dart` — debug/test utility
- `lib/services/storage/keychain_manager.dart` — centralized keychain access with correct ACLs
- `lib/screens/settings/storage_settings_screen.dart`
- `lib/services/export_service.dart`
- `lib/widgets/encrypted_image.dart` (update: track last_viewed)
- `lib/providers/feed_provider.dart` (update: last_viewed tracking)
- `test/services/storage/retention_test.dart`
- `test/services/storage/encryption_audit_test.dart`

## Verification
- DB file is not readable without encryption key (test opens raw file, expects failure)
- Media files on disk are not valid images (test reads raw bytes, checks for JPEG/PNG headers — should not find them)
- Keychain entries exist with correct access control attributes
- Retention: insert events older than 30 days with old last_viewed → run retention → events deleted
- Retention: insert events older than 30 days with recent last_viewed → run retention → events kept (grace period)
- Retention: own events older than 30 days → never deleted
- Media eviction: insert 3GB of media entries → run eviction → oldest removed until under 2GB
- Storage settings: shows accurate numbers matching actual disk usage
- Clear cache: removes cached media, own content untouched
- Export: produces valid CBOR bundle, signature verifiable, re-importable

## Key decisions
- Don't clear feed key cache on screen lock. The performance cost of re-loading from DB on every resume isn't worth the marginal security gain — the keys are already encrypted at rest and the cache only exists in process memory.
- `last_viewed` grace period of 7 days. Content you looked at this week survives even if it's >30 days old.
- Export format is CBOR (matches protocol serialization). Not JSON — binary media would bloat JSON.

## Risks
- `flutter_secure_storage` on some Android devices uses EncryptedSharedPreferences which has known issues (data loss on OS update). Monitor and have a fallback plan (direct Android Keystore access).
- Retention running during sync could cause race conditions (deleting events that are being written). Use database transactions and run retention after sync completes.
- Export of large media collections could be slow and memory-intensive. Stream the CBOR output rather than building it all in memory.
