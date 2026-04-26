# Plan 06: Feed Display

## Dependencies
Plan 04 (identity, navigation), Plan 04a (design system, shared components, shell), Plan 05 (post creation, events provider)

## Scope

Render the chronological feed and profile screens. Initially shows only own posts (sync comes in Plan 09).

### Feed screen
The feed has **no page title and no `TopBar`** — per the design, the top of the screen is a single-row sync/search bar and the content starts immediately below. This is a deliberate departure from the original plan, which had a separate `TopBar` + `SyncBar`.

- Reverse-chronological list of decrypted events from all followed accounts + own
- `ListView.builder` for efficient rendering — only builds visible items
- Pull-to-refresh gesture (wired to no-op until Plan 09 adds sync)
- The top edge is `FeedSyncSearchBar` (see below) — this is the only chrome above the posts
- Empty state (no friends yet): "Add a friend to get started" + prominent invite card that opens `QrInviteSheet` (Plan 08). No QR rendered inline — the sheet owns that.
- Trailing state (end of feed reached): a small "Load older posts" link (queries older events from local DB) and, once the local DB has nothing more, an italic Fraunces "you're all caught up." note in stone color, centered, with 40px bottom breathing room.

### FeedSyncSearchBar
A single row that carries both sync status and the search affordance. Replaces the two separate widgets the original plan had (no more standalone `SyncBar` or `sync_status_indicator.dart`).

- **Default mode** (not searching, sync state present): colored `SyncDot` (from Plan 04a) + sync text on the left, magnifying-glass `IconButton` on the right.
  - `synced`: success-green dot (no pulse), "Last synced 5 min ago · N friends reachable"
  - `syncing`: sage dot with pulse animation, "Syncing…"
  - `waiting`: clay dot (no pulse), "Waiting for {FriendName}'s device…"
  - `offline`: stone dot (no pulse), "Offline — posts will sync when online."
- **Default mode, sync state suppressed** (user toggled sync display off in a future settings option, or pre-first-sync): the dot + text collapse; only the magnifying-glass sits right-aligned.
- **Search mode** (after tapping the magnifying glass): the whole row becomes a search input — magnifying-glass icon on the left, unstyled `TextField` filling the middle (placeholder "Search posts and friends"), "Cancel" text button on the right that exits search and clears the query. Input autofocuses on entry.
- Row height 44, paper background, hairline bottom border. Transitions are instantaneous on mode toggle for MVP (no morph animation — the mockup uses a fade that can come later).
- Search itself is local-only (queries the events table's caption text and follows' display names). Implementation can be a simple `LIKE` scan for MVP; switch to FTS5 if it proves slow.

### Post card widget
Matches the mockup exactly.

- Header row (padding 0/20): `Avatar sm` (28px) + author's **first name** in 14/600 ink + flex spacer + relative timestamp (e.g. "yesterday", "2d", "5d") in 12 stone.
- Photo: 4:5 portrait by default (a future tweak may allow 1:1 square). Borders: hairline top and bottom, no rounded corners, full-bleed horizontally.
- Caption (if present): 12px top padding, 15/1.5 ink.
- Action row (10px top padding, 20px horizontal): heart icon + count (clay-filled when liked, with `heart-pop` animation on tap), then chat-circle icon + count. Both are tappable; heart toggles the like (wired in Plan 10), chat/photo/caption tap opens post detail.
- Bottom spacing: 36 in comfy density, 24 in compact density (Plan 04a exposes `density` as theme-level; for MVP ship comfy).

### Post detail screen
- **Header** (custom, not `TopBar`): a row with ← back `IconButton`, `Avatar sm`, author's first name in 14/600, flex spacer, relative timestamp in 12 stone. Hairline bottom border.
- **Body scroll**: photo at 4:5, caption in 16/1.55 ink, then an action row with heart/count, chat-circle/count, flex spacer, and a **bookmark** button (see below).
- **Comments list**: placeholder until Plan 10 wires real comments. Stub: render 0–2 sample rows when `is_own=1` posts have comments associated locally.
- **Sticky composer bar** (bottom): belongs to Plan 10. Reserve the layout slot — `Row` with own `Avatar sm`, a flex `Input`, and a paper-plane-tilt send `IconButton`. Plan 10 wires the sending logic.
- **Bookmark button**: toggles the viewer's local `is_saved` flag on the event (see Plan 02 schema + Plan 10). Icon is bookmark-simple outline when unsaved, bookmark-simple-fill sage-deep when saved. Purely local — no event is produced, nothing is synced.

### Lazy media decryption
- `EncryptedImage` widget: given a media hash, decrypts and displays the photo
- In-memory LRU cache: bounded map of hash → decoded image bytes
- Cache size: configurable, default ~50 images or 100MB
- Decryption runs in a separate isolate via `compute()` to avoid jank
- Shows placeholder/shimmer while decrypting
- If media not in local cache: show placeholder with "Tap to load" (media fetching from peers comes in Plan 09)

### Own profile screen ("You" tab)
Matches the design mockup precisely.

- **Header row**: "You" title in Fraunces 22/500 on the left (no back button — this is a tab root), gear `IconButton` on the right → pushes `/settings` (Plan 15).
- **Identity block** (centered column, 20px vertical breathing):
  - `Avatar lg` (72px)
  - Display name in Fraunces 24/500, ink, letter-spacing -0.01em
  - Bio in 14/1.5 graphite, centered, max-width 240px
  - Action row: two `SecondaryButton`s side-by-side — **Share invite** (qr-code icon, opens `QrInviteSheet` from Plan 08) and **Edit** (pencil-simple icon, pushes the profile edit screen — defined later or stubbed for MVP).
- **Stats row** (centered, 32px gap between items, 20px bottom padding): "**N** friends" and "**M** posts" in 13 graphite with bold 15 ink numbers. Sourced from DB queries.
- **Post grid**: 3-column `SliverGrid`, 3px gap, 1:1 aspect squares. Tapping a cell opens the post detail. Uses compressed versions as thumbnails.

### Other profile screen (stub)
- Display name, avatar, bio
- Grid of their posts from local cache (same 3-column layout as own profile)
- "Load older posts" for backfill
- Unfollow button (wired in Plan 08)
- Last synced timestamp, connection status
- Populated after sync exists; stub the screen now

## Files created/modified
- `lib/screens/feed/feed_screen.dart` — no TopBar, `FeedSyncSearchBar` + post list + trailing "you're all caught up" state
- `lib/screens/feed/feed_sync_search_bar.dart` — single widget that handles sync display and search input (replaces the old separate `sync_status_indicator.dart`)
- `lib/screens/feed/post_card.dart`
- `lib/screens/feed/post_detail_screen.dart` — custom header row, body, bookmark toggle; composer bar slot reserved for Plan 10
- `lib/screens/profile/own_profile_screen.dart` — "You" tab root
- `lib/screens/profile/other_profile_screen.dart` (stub)
- `lib/widgets/encrypted_image.dart`
- `lib/widgets/empty_feed.dart`
- `lib/providers/feed_provider.dart`
- `lib/providers/search_provider.dart` — local search over events (caption LIKE) and follows (display_name LIKE)
- `lib/providers/bookmark_provider.dart` — toggles `is_saved` on the events table (see Plan 02)
- `lib/router.dart` (update: register feed, profile, detail routes under the tab shell defined in Plan 04a)
- `test/screens/feed/` — widget tests with mock events, including FeedSyncSearchBar state transitions and search-mode toggle

## Verification
- Feed has no page title or TopBar — only the `FeedSyncSearchBar` as top chrome
- FeedSyncSearchBar renders correctly for each state (synced / syncing with pulse / waiting / offline)
- Tapping the magnifying glass swaps the row into a focused search input; Cancel exits and clears
- Search: typing a caption substring filters the list; typing a friend's first name filters to their posts
- Create 3 posts → all appear in feed in reverse chronological order
- Photos decrypt and display correctly (no corruption)
- Scrolling 20+ posts is smooth — no decryption jank (profile with Xcode/Android profiler)
- Pull-to-refresh triggers gesture (even though no-op)
- Empty feed (no friends) shows "Add a friend" prompt + button that opens `QrInviteSheet`
- End-of-feed trailing state: "Load older posts" link, then italic "you're all caught up." note
- Own profile ("You" tab): large avatar, name, bio, stats row, Share invite / Edit actions, 3-col grid
- Tapping gear on "You" pushes Settings
- Tapping "Share invite" opens `QrInviteSheet`
- Post detail header has no TopBar — custom row with back, avatar, first name, timestamp
- Bookmark toggle on post detail: flips `is_saved` in DB, icon state updates immediately
- "Load older posts" fetches next page from local DB
- Post detail opens on tap, shows full photo + caption

## Key decisions
- LRU image cache: ~50 images in memory. Evict least-recently-used when full. This prevents OOM on long feeds.
- Decrypt in isolate: `compute()` for each image. Consider batching adjacent images for smoother scroll.
- Thumbnail for grid: use compressed version directly (already ≤1080px). No separate thumbnail generation for MVP.
- `ListView.builder` not `ListView` — critical for performance with large feeds.
- **No feed TopBar.** The design removes it; the sync/search bar carries everything the top of the screen needs. Don't reintroduce a title.
- **One combined sync/search widget.** The earlier split (separate SyncBar + standalone search affordance) duplicated visual weight at the top of the feed. Consolidating matches the design and reduces the widget count.
- **Bookmark is local-only.** Not an event kind, not synced. The spec sees "saved" as a private retention signal from the viewer, not a social signal. If we ever want "share that you saved this," that's a new feature — don't preemptively widen the protocol.

## Risks
- Decryption in isolates has overhead from data copying across isolate boundaries. For large images, this could be 50-100ms. Pre-decrypt a few images ahead of scroll position to mask latency.
- Memory pressure: 50 decoded JPEG images at ~500KB each = ~25MB. Acceptable, but monitor on low-RAM devices.
- Grid view in profile needs a different layout than the feed list. Use `SliverGrid` within a `CustomScrollView`.
