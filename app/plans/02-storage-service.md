# Plan 02: Storage Service (SQLCipher via Drift)

## Dependencies
Plan 01 (project scaffolding, abstract StorageService interface)

## Scope

Implement the encrypted local database that backs all persistent state.

### Drift + SQLCipher integration
- `drift` ORM with `sqlcipher_flutter_libs` for encrypted SQLite
- Database class extending `GeneratedDatabase`
- DB encryption key: generate random 256-bit key on first launch, store in OS keychain via `flutter_secure_storage`
- Open database with encryption key on every launch

### Tables (from app-spec.md)

```sql
identity (pubkey, private_key, feed_key, recovery_phrase, created_at)
follows (pubkey, display_name, avatar_hash, connection_card, feed_key, last_synced_at, status)
events (id, pubkey, created_at, kind, ref_id, content, media_refs, sig, is_own, fetched_at, last_viewed)
media_cache (hash, path, size, last_accessed)
outbound_follow_requests (pubkey, connection_card, created_at, status)
inbound_follow_requests (pubkey, encrypted_endpoints, created_at, status)
outbound_queue (id, target_pubkey, event_blob, created_at, retry_count)
```

Indexes: `idx_events_feed(created_at DESC)`, `idx_events_pubkey(pubkey, created_at DESC)`, `idx_events_ref(ref_id)`

### DAOs
Typed query classes for each table group:
- `IdentityDao` — get/set identity
- `FollowsDao` — CRUD follows, update last_synced, update status
- `EventsDao` — insert events, query by pubkey, query feed (all followed + own, ordered by created_at), query by ref, delete
- `MediaCacheDao` — register media, lookup by hash, LRU queries, delete
- `FollowRequestsDao` — inbound and outbound request management
- `OutboundQueueDao` — enqueue, dequeue, retry count increment

### StorageService implementation
Implement the abstract `StorageService` from Plan 01 with the Drift-backed DAOs.

### Retention policy
- Events from others: evict when older than 30 days AND not recently viewed (LRU grace)
- Media from others: LRU eviction when total cache exceeds 2GB
- Own content (`is_own=1`): never evicted
- Retention runs on app open (not in a loop, just once per launch)

### Migration strategy
- Even though v1 has no migrations, establish the pattern: numbered schema versions, migration callbacks
- This prevents pain when the schema changes in future versions

## Files created/modified
- `lib/services/storage/database.dart` — Drift database definition
- `lib/services/storage/tables/` — one file per table
- `lib/services/storage/daos/identity_dao.dart`
- `lib/services/storage/daos/follows_dao.dart`
- `lib/services/storage/daos/events_dao.dart`
- `lib/services/storage/daos/media_cache_dao.dart`
- `lib/services/storage/daos/follow_requests_dao.dart`
- `lib/services/storage/daos/outbound_queue_dao.dart`
- `lib/services/storage/drift_storage_service.dart`
- `lib/services/storage/retention.dart`
- `lib/providers/service_providers.dart` (update: wire real StorageService)
- `test/services/storage/` — DAO tests, retention tests

## Verification
- All tables create successfully on fresh launch
- CRUD operations work for every table
- DB file on disk is encrypted (not readable as raw SQLite)
- DB opens correctly with key from secure storage
- Retention: insert old events, run eviction, verify removed
- Retention: own events are never evicted regardless of age
- Media LRU: insert entries exceeding 2GB total, run eviction, verify oldest-accessed removed first
- App launches with real database on device (both platforms)

## Key decisions
- `flutter_secure_storage` for keychain access (widely used, supports both platforms). If it proves unreliable on specific Android devices, fall back to direct Android Keystore FFI.
- Drift code generation via `build_runner` — same pipeline as Riverpod generators
- `private_key` column in identity table is a reference/flag — the actual key lives in OS keychain, not in the database

## Risks
- `sqlcipher_flutter_libs` requires careful Podfile/Gradle configuration. iOS may need `pod 'SQLCipher'` explicitly. Android may conflict with default sqlite3 libs. Test on real devices early.
- Drift code generation can be slow on large schemas. Keep generated files in version control to avoid regenerating on every build.
