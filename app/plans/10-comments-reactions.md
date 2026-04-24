# Plan 10: Comments & Reactions

## Dependencies
Plan 05 (post creation — event model), Plan 06 (feed display — post detail screen), Plan 09 (LAN sync — delivery mechanism)

## Scope

Add comments and likes to posts, with delivery to the post author via the sync/outbound queue.

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
- Comments list below the photo/caption, ordered by created_at
- Comment input field at bottom
- Like button (filled/unfilled state based on whether you've liked)
- Like count
- Comment count shown on post cards in feed

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
- `lib/services/outbound_queue_service.dart`
- `lib/screens/feed/post_detail_screen.dart` (update: add comments + reactions UI)
- `lib/screens/feed/post_card.dart` (update: show comment/like counts)
- `lib/widgets/comment_list.dart`
- `lib/widgets/comment_input.dart`
- `lib/widgets/reaction_button.dart`
- `lib/providers/comments_provider.dart`
- `lib/providers/reactions_provider.dart`
- `lib/server/handlers/events_push_handler.dart` — POST /events (receive pushed events)
- `lib/server/http_server.dart` (update: add POST /events route)
- `lib/sync/sync_engine.dart` (update: process outbound queue during sync)
- `test/services/comment_service_test.dart`
- `test/services/outbound_queue_service_test.dart`

## Verification
- Comment on own post: appears in post detail immediately
- Like own post: count increments, button fills
- Unlike (toggle): like removed, count decrements
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

## Risks
- Comment ordering relies on `created_at` timestamps. Device clocks may differ slightly. Accept minor ordering inconsistencies — not worth adding a vector clock for MVP.
- The `POST /events` endpoint introduces a write path on the server. Must validate that the pushing pubkey is a recognized follower and the event signature is valid. Reject all others.
- Outbound queue adds complexity to the sync engine. Keep it simple: process queue at the end of each sync cycle, don't interleave with event fetching.
