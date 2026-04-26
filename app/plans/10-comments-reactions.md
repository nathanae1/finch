# Plan 10: Comments, Reactions & Save

## Dependencies
Plan 02 (storage — `is_saved` column and retention exception), Plan 05 (post creation — event model), Plan 06 (feed display — post detail screen, composer-bar slot, bookmark affordance), Plan 09 (LAN sync — delivery mechanism)

## Scope

Add comments and likes to posts (synced social signals) and the local-only Save/bookmark feature (private retention override). Deliver comments and likes to the post author via the sync/outbound queue. Save is purely local — no event, no sync.

### Comment creation (kind=4)
- Event with `kind=4`, `ref=target_post_id`, `content=comment_text`, `extensions={}`
- Signed and encrypted via `ContentKeyService.encryptForAudience(event, Audience.broadcast)`
- Stored locally

### Like creation (kind=5)
- Event with `kind=5`, `ref=target_post_id`, `content=""` (empty), `extensions={}`
- Signed and encrypted via `ContentKeyService.encryptForAudience(event, Audience.broadcast)`
- One like per user per post (toggle: like again = create kind=6 delete event referencing the like)

### Outbound delivery
- Comments/likes on **own posts**: just stored locally, available to followers via normal sync
- Comments/likes on **others' posts**: need to reach the post author
  - Queue the encrypted event in `outbound_queue` table: target_pubkey, event_blob, created_at
  - On next sync with the target peer, push queued events
  - Add `POST /events` endpoint to the on-device server (for receiving pushed events from followers)
  - The author's device receives, decrypts, verifies, stores the event
  - Author's device then serves these events to other followers during normal sync

### Outbound queue processing
- During sync: check outbound_queue for events targeting the current peer
- Push via HTTP to peer's server
- On success: remove from queue
- On failure: increment retry_count, retry on next sync
- Max 3 retries, then drop (peer may have unfollowed or gone permanently offline)

### Post detail screen update
Wires real content into the layout slots defined in Plan 06.

- **Like button**: heart icon with `heart-pop` animation on tap. Outline (graphite) when not liked, **filled clay** when liked, matching the design. The count increments immediately on tap (optimistic local update) even if the like event hasn't been synced yet.
- **Comment count + list**: comments list below the photo/caption/actions, ordered ascending by created_at. Each comment row: `Avatar sm`, commenter's first name in 13/600 + relative timestamp in stone, comment text in 14/ink below.
- **Sticky composer bar** (bottom of the screen, owned by this plan): `Row` with own `Avatar sm`, a flex `Input` with placeholder "Say something kind…", and a paper-plane-tilt `IconButton` in sage-deep that submits the comment. The row sits above the home-indicator safe-area inset. Submitting clears the input and optimistically appends the new comment.
- Comment count shown on post cards in feed (Plan 06 slot).

### Save (bookmark) — local-only
A private, per-viewer retention override. Not a synced event kind. Implementation: flips the `is_saved` column on the events table (see Plan 02 schema + retention exception).

- **Affordance**: bookmark-simple icon in the post detail action row (Plan 06 slot). Outline (graphite) when unsaved, **bookmark-simple-fill** in sage-deep when saved. Tapping toggles.
- **Effect**: saved events (and their referenced media blobs) are exempt from retention eviction — see Plan 02's retention policy and Plan 12's enforcement. No UI pops up; the eviction exception is silent.
- **No protocol impact**: no kind=? event is produced, no sync traffic, no follower sees the bookmark. If we ever want "share that you saved this," that's a new feature with its own design conversation — do not preemptively leak saves into the protocol.
- **No "Saved" view in MVP**: the current UX is "save extends retention." A dedicated Saved tab/filter can come later; until then, saved posts just stay in the feed longer than unsaved ones.

### Delete own comment/reaction (kind=6)
- Create kind=6 event with ref=comment_or_like_event_id
- Queue for delivery if the comment was on someone else's post
- UI removes the item immediately

### Display logic
- Only show comments from people the viewer follows (prevents spam from unknown pubkeys)
- Group likes: "3 likes" rather than listing each one
- Comment author: show display name from follows table or "Unknown" if not followed

## Files created/modified
- `lib/services/comment_service.dart`
- `lib/services/reaction_service.dart`
- `lib/services/save_service.dart` — toggles `is_saved` on an event row; local-only
- `lib/services/outbound_queue_service.dart`
- `lib/screens/feed/post_detail_screen.dart` (update: wire comments + reactions + bookmark toggle + sticky composer into the Plan 06 slots)
- `lib/screens/feed/post_card.dart` (update: show comment/like counts, heart-pop on tap from the feed card)
- `lib/widgets/comment_list.dart`
- `lib/widgets/comment_input.dart` — the sticky composer (Avatar sm + Input + paper-plane IconButton)
- `lib/widgets/reaction_button.dart` — heart with pop animation and clay-filled state
- `lib/widgets/bookmark_button.dart` — bookmark-simple toggle, sage-deep filled state
- `lib/providers/comments_provider.dart`
- `lib/providers/reactions_provider.dart`
- (no new bookmark_provider here — it lives in Plan 06 alongside the bookmark affordance; this plan just wires the `save_service` the provider delegates to)
- `lib/server/handlers/events_push_handler.dart` — POST /events (receive pushed events)
- `lib/server/http_server.dart` (update: add POST /events route)
- `lib/sync/sync_engine.dart` (update: process outbound queue during sync)
- `test/services/comment_service_test.dart`
- `test/services/save_service_test.dart` — toggle on/off, verifies `is_saved` flag flips and no event is produced
- `test/services/outbound_queue_service_test.dart`

## Verification
- Comment on own post: appears in post detail immediately
- Sticky composer sits above the home-indicator safe area; remains visible when keyboard opens (scrolls the comments list, not the bar)
- Submitting the composer clears the input and appends the comment optimistically
- Like own post: count increments, heart-pop animation plays, heart fills clay
- Unlike (toggle): like removed, count decrements, heart returns to outline graphite
- Bookmark/save: tapping the bookmark icon flips `is_saved` on the event row; icon renders as sage-deep filled when saved; no event is written, no sync traffic
- Retention behavior: a saved event older than the 30-day window is not evicted (see Plan 02 / Plan 12 verification)
- Comment on friend's post: event queued in outbound_queue
- Sync with friend: queued comment delivered, friend sees it on their device
- Friend's comments on your post: appear after sync
- Delete own comment: kind=6 event created, comment removed from view
- Multiple comments from multiple users: all display correctly, ordered by time
- Only comments from followed accounts are shown
- Outbound queue: 3 failed retries → event dropped

## Key decisions
- Just "like" for MVP, no emoji reactions. Keeps it simple.
- Only show comments from followed accounts. Prevents abuse from unfollowed accounts that somehow have your feed key (pre-rotation scenario).
- Outbound queue max 3 retries then drop. The comment isn't critical enough to retry indefinitely.
- `POST /events` on the on-device server accepts pushed events from any followed account (verified by checking follows table).
- **Save is local-only.** A bookmark is a private "keep this" signal from the viewer, not a social signal. Encoding it as an event would either (a) leak the viewer's attention patterns to the author or (b) require a new encrypted-to-self event kind that the protocol doesn't currently want. Neither is worth the surface area. If a "share what you saved" feature ever ships, it's a new social primitive, not a retrofit.
- **Composer placeholder "Say something kind…"** is a deliberate tone nudge. It's cheap to change later; keep it unless user research says otherwise.

## Risks
- Comment ordering relies on `created_at` timestamps. Device clocks may differ slightly. Accept minor ordering inconsistencies — not worth adding a vector clock for MVP.
- The `POST /events` endpoint introduces a write path on the server. Must validate that the pushing pubkey is a recognized follower and the event signature is valid. Reject all others.
- Outbound queue adds complexity to the sync engine. Keep it simple: process queue at the end of each sync cycle, don't interleave with event fetching.
