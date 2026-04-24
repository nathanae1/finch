# Plan 13: Feed Key Rotation on Unfollow

## Dependencies
Plan 03 (crypto — key generation, encryption), Plan 08 (follow flow — unfollow trigger), Plan 09 (sync engine — key distribution)

## Scope

When you remove a follower, generate a new feed key so they can no longer decrypt your new posts.

### Rotation trigger
- User unfollows/removes someone (or blocks them)
- `FollowService.removeFollower(pubkey)` triggers rotation

### Rotation steps
1. **Generate new feed key**: random 256-bit key via CryptoService (primitive)
2. **Retain old key**: store in a `feed_key_history` table with the timestamp range it was active for
3. **Set new key as current**: update `identity.feed_key` in DB, update ContentKeyService's in-memory cache
4. **Encrypt new key for each remaining follower** (ContentKeyService):
   - For each pubkey in `follows` table (excluding the removed one):
   - Derive shared key via X25519 DH (CryptoService primitive)
   - Encrypt new feed key with shared key (ContentKeyService)
   - Store in a `pending_key_distributions` table: `{ target_pubkey, encrypted_feed_key, nonce }`
5. **New posts use the new key**: `ContentKeyService.getCurrentFeedKey()` always returns the latest

### Key distribution (lazy, during sync)
- During sync with a follower, check `pending_key_distributions` for their pubkey
- If pending: include the encrypted feed key in the sync response
- Add a new endpoint or extend /manifest response: `{ ..., new_feed_key: { encrypted_feed_key, nonce } }`
- Follower receives new key, decrypts, updates their `follows.feed_key`
- Mark distribution as completed
- Follower can now decrypt new posts

### Multi-key decryption
- When decrypting an event, the feed key used depends on when it was created
- Try current feed key first (most common case)
- If decryption fails (authentication error), try historical keys in reverse chronological order
- Store a `key_epoch` in encrypted event metadata to speed up key selection (avoid trial decryption)
  - Or: use `created_at` timestamp to determine which key epoch the event belongs to
  - Decision: use timestamp-based lookup. Each key history entry has `valid_from` and `valid_until`. Look up by event's `created_at`.

### Feed key history table
```sql
CREATE TABLE feed_key_history (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    feed_key    BLOB NOT NULL,
    valid_from  INTEGER NOT NULL,
    valid_until INTEGER NOT NULL  -- timestamp when this key was rotated out
);
```

### Pending key distributions table
```sql
CREATE TABLE pending_key_distributions (
    target_pubkey       TEXT NOT NULL,
    encrypted_feed_key  BLOB NOT NULL,
    nonce               BLOB NOT NULL,
    created_at          INTEGER NOT NULL,
    distributed         INTEGER DEFAULT 0,
    PRIMARY KEY (target_pubkey, created_at)
);
```

### Receiving a rotated key (as a follower)
- During sync, if the peer's response includes a `new_feed_key` field
- Decrypt with X25519 DH shared key
- Update `follows.feed_key` with the new key
- Update feed key cache in memory

## Files created/modified
- `lib/services/crypto/key_rotation_service.dart`
- `lib/services/storage/tables/feed_key_history.dart`
- `lib/services/storage/tables/pending_key_distributions.dart`
- `lib/services/storage/daos/key_rotation_dao.dart`
- `lib/services/storage/database.dart` (update: new tables, migration)
- `lib/services/follow_service.dart` (update: trigger rotation on unfollow)
- `lib/services/crypto/pairwise_content_key_service.dart` (update: multi-key decryption, rotation logic)
- `lib/services/crypto/key_cache.dart` (update: include historical keys, used by ContentKeyService)
- `lib/sync/sync_engine.dart` (update: distribute keys, receive rotated keys)
- `lib/server/handlers/manifest_handler.dart` (update: include pending key distribution)
- `test/services/crypto/key_rotation_test.dart`

## Verification

**Full scenario test:**
1. Alice has followers Bob and Carol
2. Alice removes Bob
3. New feed key generated, old key stored in history
4. Carol syncs with Alice → receives new feed key
5. Alice posts a new photo (encrypted with new key)
6. Carol syncs → decrypts new post successfully
7. Bob syncs → cannot decrypt new post (only has old key)
8. Bob can still read old posts (encrypted with old key, which he still has)

**Additional checks:**
- Old posts still decryptable after rotation (historical key lookup works)
- Multiple rotations: 3 sequential rotations, all historical keys retained, events from each epoch decryptable
- Pending distribution cleared after successful delivery
- Concurrent rotation and posting: post during rotation uses the correct key (mutex ensures atomicity)
- Feed key cache updated after rotation (in-memory cache reflects new key)

## Key decisions
- Timestamp-based key lookup rather than explicit key epoch in events. Simpler, avoids changing the encrypted event format. Assumes device clocks are reasonably accurate (within a few seconds is fine).
- Retain all historical keys (32 bytes each, negligible storage). Never delete them — needed to decrypt old cached content.
- Lazy distribution: followers get the new key on their next sync. During the gap, they can't decrypt new posts. This is acceptable — they'll catch up.
- Mutex around rotation: only one rotation can happen at a time. If two unfollows happen in quick succession, they queue. Each generates a new key.

## Risks
- **This is the most complex crypto operation in the app.** Thorough testing is essential. A bug here means either privacy failure (removed follower can still read) or data loss (current followers can't decrypt).
- Race condition: post created during rotation might use wrong key. Use a mutex/lock that blocks post creation during key rotation (rotation takes <100ms, negligible delay).
- If a follower is offline for a very long time, they'll miss multiple key rotations. On their next sync, they receive only the latest key. They won't be able to decrypt posts from intermediate key epochs unless we distribute the full key chain. Decision for MVP: only distribute the current key. Missed intermediate posts are acceptable — they're likely expired by retention anyway.
