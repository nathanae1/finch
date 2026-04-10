# Plan 06: Feed Display

## Dependencies
Plan 04 (identity, navigation), Plan 05 (post creation, events provider)

## Scope

Render the chronological feed and profile screens. Initially shows only own posts (sync comes in Plan 09).

### Feed screen
- Reverse-chronological list of decrypted events from all followed accounts + own
- `ListView.builder` for efficient rendering — only builds visible items
- Pull-to-refresh gesture (wired to no-op until Plan 09 adds sync)
- Sync status indicator: "Last synced: never" / "Last synced: 5 min ago" / "Syncing..."
- Empty state: "Add a friend to get started" + prominently show QR code and invite link
- "Load older posts" button at bottom (queries older events from local DB)

### Post card widget
- Author avatar + display name + timestamp
- Photo (lazy-loaded, decrypted)
- Caption text
- Comment count + like count (tappable, detail comes in Plan 10)
- Tap → post detail screen

### Post detail screen
- Full-screen photo + caption
- Comments list and reactions (placeholder until Plan 10)
- Author info

### Lazy media decryption
- `EncryptedImage` widget: given a media hash, decrypts and displays the photo
- In-memory LRU cache: bounded map of hash → decoded image bytes
- Cache size: configurable, default ~50 images or 100MB
- Decryption runs in a separate isolate via `compute()` to avoid jank
- Shows placeholder/shimmer while decrypting
- If media not in local cache: show placeholder with "Tap to load" (media fetching from peers comes in Plan 09)

### Own profile screen
- Display name, avatar, bio
- Grid of own posts (thumbnails from compressed versions)
- QR code button → shows connection card QR full-screen
- Share button → copies invite link to clipboard
- Follower count + following count (from DB queries)
- Settings gear → navigates to settings (placeholder until Plan 15)

### Other profile screen (stub)
- Display name, avatar, bio
- Grid of their posts from local cache
- "Load older posts" for backfill
- Unfollow button (wired in Plan 08)
- Last synced timestamp, connection status
- Populated after sync exists; stub the screen now

## Files created/modified
- `lib/screens/feed/feed_screen.dart`
- `lib/screens/feed/post_card.dart`
- `lib/screens/feed/post_detail_screen.dart`
- `lib/screens/profile/own_profile_screen.dart`
- `lib/screens/profile/other_profile_screen.dart` (stub)
- `lib/widgets/encrypted_image.dart`
- `lib/widgets/sync_status_indicator.dart`
- `lib/widgets/empty_feed.dart`
- `lib/providers/feed_provider.dart`
- `lib/router.dart` (update: add feed, profile, detail routes)
- `test/screens/feed/` — widget tests with mock events

## Verification
- Create 3 posts → all appear in feed in reverse chronological order
- Photos decrypt and display correctly (no corruption)
- Scrolling 20+ posts is smooth — no decryption jank (profile with Xcode/Android profiler)
- Pull-to-refresh triggers gesture (even though no-op)
- Empty feed shows "Add a friend" prompt with QR code
- Own profile shows post grid, QR button works, share copies link
- "Load older posts" fetches next page from local DB
- Post detail opens on tap, shows full photo + caption

## Key decisions
- LRU image cache: ~50 images in memory. Evict least-recently-used when full. This prevents OOM on long feeds.
- Decrypt in isolate: `compute()` for each image. Consider batching adjacent images for smoother scroll.
- Thumbnail for grid: use compressed version directly (already ≤1080px). No separate thumbnail generation for MVP.
- `ListView.builder` not `ListView` — critical for performance with large feeds.

## Risks
- Decryption in isolates has overhead from data copying across isolate boundaries. For large images, this could be 50-100ms. Pre-decrypt a few images ahead of scroll position to mask latency.
- Memory pressure: 50 decoded JPEG images at ~500KB each = ~25MB. Acceptable, but monitor on low-RAM devices.
- Grid view in profile needs a different layout than the feed list. Use `SliverGrid` within a `CustomScrollView`.
