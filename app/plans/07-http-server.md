# Plan 07: On-Device HTTP Server

## Dependencies
Plan 02 (storage — query events/media), Plan 03 (crypto — for follow request handling), Plan 05 (events exist to serve)

## Scope

Run a shelf-based HTTP server inside the app that serves your content to peers.

### Server setup
- Built with `shelf` + `shelf_router`
- Binds to `0.0.0.0` on a random high port (49152-65535)
- Port selection: try random port, retry up to 5 times if bound
- Starts on app launch, stops on app terminate
- Serves only the device owner's content (single-user model)

### Endpoints (per protocol spec)

**GET /status**
- Response: JSON `{ pubkey, version: "2026-03-24", event_count, storage_used }`
- No auth required
- Used by peers for version check before sync

**GET /manifest?since={ts}&until={ts}**
- Returns CBOR: `{ pubkey, events: [{ id, created_at }], has_older: bool }`
- Queries events table for own events within timestamp range
- Lightweight — no payloads, just IDs and timestamps

**GET /events?since={ts}**
- Returns CBOR-serialized `Envelope` containing `EnvelopeItem`s of type `"event"`, each wrapping an `EncryptedEvent`
- Only own events (is_own=1) after the given timestamp

**GET /media/{blake2b_hash}**
- Returns raw encrypted media blob from filesystem
- Content-Type: `application/octet-stream`
- 404 if hash not found in media_cache

**POST /follow-request**
- Body: CBOR `{ requester_pubkey, encrypted_return_endpoints, nonce }`
- Validates body structure
- Stores in `inbound_follow_requests` table
- Returns 202 Accepted

### Middleware
- **Rate limiting**: per-IP, max 120 requests/minute. Returns 429 when exceeded.
- **Request size limit**: max 1MB body for POST endpoints
- **Error handling**: catch exceptions, return appropriate HTTP status codes, never leak stack traces

### Server lifecycle
- `ServerProvider` (Riverpod): manages server start/stop, exposes port number
- Start on app launch (after identity loaded)
- Stop on app terminate / background (iOS)
- Expose current port for mDNS registration (Plan 09) and Tor onion service (Plan 11)

## Files created/modified
- `lib/server/http_server.dart` — shelf pipeline setup, start/stop
- `lib/server/handlers/status_handler.dart`
- `lib/server/handlers/manifest_handler.dart`
- `lib/server/handlers/events_handler.dart`
- `lib/server/handlers/media_handler.dart`
- `lib/server/handlers/follow_request_handler.dart`
- `lib/server/middleware/rate_limit.dart`
- `lib/server/middleware/error_handler.dart`
- `lib/providers/server_provider.dart`
- `test/server/status_handler_test.dart`
- `test/server/manifest_handler_test.dart`
- `test/server/events_handler_test.dart`
- `test/server/media_handler_test.dart`
- `test/server/follow_request_handler_test.dart`

## Verification
- Server starts on app launch, binds to a port
- `curl http://localhost:{port}/status` → valid JSON with correct pubkey and version
- `curl http://localhost:{port}/manifest?since=0` → CBOR with list of own event IDs
- `curl http://localhost:{port}/events?since=0` → CBOR Envelope containing EnvelopeItems of type "event"
- `curl http://localhost:{port}/media/{hash}` → encrypted blob bytes (correct size)
- `curl http://localhost:{port}/media/nonexistent` → 404
- POST to `/follow-request` with valid CBOR → 202, entry in inbound_follow_requests table
- POST to `/follow-request` with invalid body → 400
- Rate limiting: 121 rapid requests → 429 on the 121st
- Server stops cleanly on app close (no port leak)

## Key decisions
- Random high port (49152-65535) avoids conflicts with well-known services. Port is ephemeral — communicated via mDNS and connection card, not hardcoded.
- Envelope is the response format for /events — items are typed EnvelopeItems, envelope-level fields are untrusted hints (see protocol spec trust model)
- CBOR responses for data endpoints, JSON for /status (human-readable for debugging)
- No CORS headers needed (device-to-device, no browser involved)
- No TLS on the local server — content payloads are E2E encrypted. LAN metadata exposure is the accepted trade-off from the spec.

## Risks
- iOS kills background processes aggressively. The server only runs in foreground on iOS. This is expected — document it, don't fight it.
- Port exhaustion is theoretically possible but practically unlikely with random high ports.
- The server must handle concurrent requests (multiple peers syncing simultaneously). shelf handles this natively with async handlers.
