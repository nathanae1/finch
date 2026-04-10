# Plan 16 — Voice Chatrooms

Voice chatrooms are the first real-time feature and the hardest to fit into Finch's P2P, serverless architecture. The core tension: Finch is async by design (seconds-to-hours latency is fine), but voice needs <200ms round-trip. Tor (3-5s) is unusable for audio. This plan addresses how to deliver voice within Finch's constraints.

**Prerequisites**: Plans 07 (HTTP server), 08 (follow flow / key exchange), 09 (LAN sync / mDNS), 11 (Tor).

## Architecture

Two new communication channels, separate from the existing feed sync:

```
Signaling (room setup, ICE exchange)     Audio (actual voice)
  WebSocket on shelf server                WebRTC via flutter_webrtc
  Encrypted with pairwise X25519 keys     Encrypted with DTLS-SRTP
  Works over LAN or Tor                    Works over LAN or hole-punched WAN
  Tolerates high latency                   Requires <200ms RTT
```

### New Service Interfaces

**SignalingService** — persistent bidirectional channels between peers (WebSocket). Generic enough for future real-time features (DMs, typing indicators).

```dart
abstract class SignalingService {
  Future<SignalingChannel> connect(ConnectionCard peer);
  void onInboundConnection(void Function(SignalingChannel) handler);
  Future<void> closeAll();
}
```

**VoiceService** — WebRTC peer connections, audio capture, room lifecycle.

```dart
abstract class VoiceService {
  Future<void> init();
  Future<VoiceRoom> createRoom({required String name, required List<String> invitedPubkeys});
  Future<void> joinRoom(VoiceRoom room, Uint8List roomSessionKey);
  Future<void> leaveRoom();
  Future<void> closeRoom();
  Future<void> setMicMuted(bool muted);
  Future<void> setSpeakerMode(bool speaker);
  Future<RTCSessionDescription> createOffer(String peerPubkey);
  Future<RTCSessionDescription> createAnswer(String peerPubkey, RTCSessionDescription offer);
  Future<void> addIceCandidate(String peerPubkey, RTCIceCandidate candidate);
  VoiceRoom? get currentRoom;
  Stream<VoiceRoomState> get roomStateStream;
  Stream<Map<String, double>> get audioLevelStream;
}
```

Both follow the existing pattern: abstract interface in `lib/services/`, mock in `lib/services/mocks/`, real implementation behind Riverpod provider.

## Protocol Additions

### New Event Kinds

| Kind | Name | Content | Ephemeral |
|------|------|---------|-----------|
| 10 | RoomCreate | `{ room_id, name, invited_pubkeys }` | Yes |
| 11 | RoomJoin | `{ room_id }` | Yes |
| 12 | RoomLeave | `{ room_id }` | Yes |
| 13 | RoomClose | `{ room_id }` | Yes |

Kinds 7-9 reserved for future feed events (DMs, groups, etc.).

### Ephemeral Events

Room signaling events are **not** part of the persistent feed:
- Delivered via WebSocket signaling channel, not `/manifest` or `/events`
- Signed with Ed25519 (authentication) but encrypted **per-recipient** with pairwise X25519 keys, not the feed key
- Never stored in the events table — processed immediately and discarded
- Convention: `kind >= 10` = ephemeral

Envelope:
```
EphemeralEncryptedEvent {
  sender_pubkey:    string
  recipient_pubkey: string
  nonce:            bytes[24]
  payload:          XChaCha20-Poly1305(pairwise_key, nonce, cbor(Event))
}
```

The pairwise key is derived the same way as for feed key exchange but with a distinct salt:
`HKDF-SHA256(X25519_DH(my_sk, their_pk), salt="finch-signaling-v1")`

### WebSocket Endpoint

New route on shelf server: **`GET /ws/signal`**

- Auth via headers on upgrade: `X-Finch-Pubkey` + `X-Finch-Sig` (Ed25519 sign of `"websocket-upgrade" + timestamp`)
- Rejects if timestamp >30s old (replay protection)
- Carries CBOR-serialized `EphemeralEncryptedEvent` frames
- Heartbeat: ping/pong every 30s, close after 3 missed

## NAT Traversal Strategy

Without developer-operated TURN servers:

| Scenario | Audio works? | Latency |
|----------|-------------|---------|
| LAN (same WiFi) | Always | <10ms |
| WAN, hole-punch succeeds (~70%) | Yes | 50-200ms |
| WAN, hole-punch fails (~30%) | **No** (v1) | N/A |
| WAN, Tor-only path | **No** — Tor too slow for audio | N/A |

### Phased approach:
1. **v1**: LAN + STUN hole-punch. If ICE fails, UI shows "Cannot connect — try the same network or set up a relay." Honest about the limitation.
2. **v2 — Participant-as-relay**: If A cannot reach C but both can reach B, B relays audio between them. Improves WAN coverage to ~95% in group calls.
3. **v3 — Relay-as-TURN**: Spare-device relay gets UDP forwarding. User-configured external TURN supported via `RTCConfiguration.iceServers`.

### When hole-punching fails

Hole-punching fails when the NAT assigns a different external port for each destination (symmetric NAT). STUN reveals your port as seen by the STUN server, but the NAT picks a different port when you send to the actual peer. Specific real-world cases:

- **Both peers on mobile data (LTE/5G)** — carriers use CGNAT, often symmetric. Most common failure.
- **Corporate / university network** — enterprise firewalls block unsolicited inbound UDP.
- **Hotel / airport / coffee shop WiFi** — captive portals with restrictive NAT.
- **Double NAT** — ISP CGNAT + user's router. If either layer is symmetric, it breaks.

## Group Topology

### v1: Full Mesh (2-4 participants)

Each device connects to every other. At N=4: 3 connections per device, ~192kbps up/down (Opus @ 64kbps). Trivial for any phone/network.

**Hard cap: 4 participants in v1.**

### v2: Mixer Node (5-8 participants)

One participant (best connectivity) or a spare-device relay acts as mixer/SFU — receives all streams, sends N-1 mixed streams. Reduces per-device load from O(N) to O(1).

**Hard cap: 8 participants.** Beyond this, even a mixer on a phone struggles with CPU/battery.

## Encryption

### Signaling
Pairwise X25519 key exchange (reuses existing crypto infrastructure):
- Derive key: `HKDF-SHA256(X25519_DH(my_sk, their_pk), salt="finch-signaling-v1")`
- Encrypt: `XChaCha20-Poly1305(pairwise_key, random_nonce, message)`

### Audio
DTLS-SRTP (WebRTC built-in):
- SDP offer/answer containing DTLS fingerprints exchanged over E2E encrypted signaling channel
- WebRTC verifies fingerprints during DTLS handshake
- SRTP keys derived from DTLS session
- Result: E2E encrypted audio — attacker must compromise both signaling encryption AND DTLS

### Room Session Key
- Creator generates random 256-bit key, distributes to each participant via pairwise X25519 encryption
- Used as authentication data (proves room membership), **not** as audio encryption key
- DTLS-SRTP provides forward secrecy per audio stream (a static room key would not)

## Room Access Model

- Voice rooms are invite-only among **mutual follows** (both parties follow each other)
- Creator selects participants from mutual follow list
- No open/discoverable rooms — consistent with Finch's "no strangers" principle

## Storage Changes

Two new tables (ephemeral, 7-day retention):

```sql
CREATE TABLE voice_rooms (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    creator_pubkey  TEXT NOT NULL,
    created_at      INTEGER NOT NULL,
    ended_at        INTEGER,
    participant_count INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE voice_room_participants (
    room_id     TEXT NOT NULL REFERENCES voice_rooms(id),
    pubkey      TEXT NOT NULL,
    joined_at   INTEGER NOT NULL,
    left_at     INTEGER,
    PRIMARY KEY (room_id, pubkey)
);

CREATE INDEX idx_voice_rooms_recent ON voice_rooms(created_at DESC);
```

Add to `StorageService` (`lib/services/storage_service.dart`):
- `saveVoiceRoom`, `updateVoiceRoomEnded`, `getRecentVoiceRooms`, `saveVoiceRoomParticipant`, `evictOldVoiceRooms`

## New Types

Add to `lib/services/types.dart` or new `lib/models/voice_room.dart`:

```dart
class VoiceRoom {
  final String id;
  final String name;
  final String creatorPubkey;
  final int createdAt;
  final List<VoiceParticipant> participants;
  final List<String> invitedPubkeys;
}

class VoiceParticipant {
  final String pubkey;
  final String? displayName;
  final bool isMuted;
  final bool isSpeaking;
  final ParticipantConnectionState connectionState;
}

enum ParticipantConnectionState {
  connecting, connected, reconnecting, disconnected
}

class VoiceRoomState {
  final VoiceRoom room;
  final bool localMuted;
  final bool speakerMode;
}

class SignalingChannel {
  final String remotePubkey;
  final PeerTransport transport;
  Future<void> send(SignalingMessage message);
  Stream<SignalingMessage> get messages;
  bool get isOpen;
  Future<void> close();
}

class SignalingMessage {
  final SignalingMessageType type;
  final String roomId;
  final String senderPubkey;
  final Map<String, dynamic> payload;
  final int timestamp;
}

enum SignalingMessageType {
  roomInvite, roomAccept, roomDecline, roomLeave, roomClose,
  offer, answer, iceCandidate, muteStatus, speakingStatus
}
```

## UI Screens

| Screen | Purpose |
|--------|---------|
| **Room List** | "Start a Room" button + recent room history (last 10) |
| **Create Room** | Name field + mutual follow picker (max 3 invitees) |
| **Incoming Invite Sheet** | Modal: room name, creator, "Join" / "Decline", 60s auto-dismiss |
| **Active Room** | Participant avatar grid with speaking indicators, mute/speaker/leave buttons, connection quality dots, elapsed time |
| **Call Overlay** | Floating mini-banner when navigating away mid-call |

## Dependencies

```yaml
flutter_webrtc: ^0.12.x        # WebRTC peer connections + audio
shelf_web_socket: ^2.0.x        # WebSocket upgrade for shelf server
web_socket_channel: ^3.0.x      # Outbound WebSocket client
wakelock_plus: ^1.2.x           # Keep screen awake during call
permission_handler: ^11.x       # Microphone permission
```

No new native FFI — `flutter_webrtc` ships its own platform binaries.

## Implementation Phases

### Phase A: Signaling Infrastructure
**Depends on**: Plan 07 (server), Plan 08 (follow flow)

New files:
- `lib/services/signaling_service.dart` — abstract interface
- `lib/services/signaling/ws_signaling_service.dart` — WebSocket implementation
- `lib/services/mocks/mock_signaling_service.dart`
- `lib/server/handlers/signaling_handler.dart` — WebSocket upgrade handler
- `lib/models/signaling_message.dart` — message types
- `lib/models/ephemeral_encrypted_event.dart` — pairwise-encrypted envelope

Modified:
- `lib/server/http_server.dart` — add `/ws/signal` route
- `lib/providers/service_providers.dart` — add `signalingServiceProvider`

**Verify**: Two devices on LAN establish WebSocket, exchange encrypted messages, auth rejects invalid signatures.

### Phase B: Voice Service Core
**Depends on**: Phase A

New files:
- `lib/services/voice_service.dart` — abstract interface
- `lib/services/voice/webrtc_voice_service.dart` — flutter_webrtc implementation
- `lib/services/mocks/mock_voice_service.dart`
- `lib/models/voice_room.dart` — VoiceRoom, VoiceParticipant, VoiceRoomState types
- `lib/providers/voice_provider.dart`

**Verify**: Two devices on LAN establish WebRTC connection via signaling, bidirectional audio works, mute works, clean disconnect.

### Phase C: Room Management
**Depends on**: Phase B

New files:
- `lib/services/voice/room_manager.dart` — room lifecycle orchestration
- `lib/services/storage/tables/voice_rooms_table.dart`
- `lib/services/storage/tables/voice_room_participants_table.dart`
- `lib/services/storage/daos/voice_rooms_dao.dart`

Modified:
- `lib/models/event_kind.dart` — add kinds 10-13
- `lib/services/storage_service.dart` — add voice room methods
- `lib/services/storage/drift_storage_service.dart` — implement voice room methods
- `lib/services/storage/database.dart` — schema migration

**Verify**: Create room, invite peer, peer joins, 3-person mesh works, leave/close room, metadata persisted to DB.

### Phase D: UI
**Depends on**: Phase C

New files:
- `lib/screens/voice/room_list_screen.dart`
- `lib/screens/voice/create_room_screen.dart`
- `lib/screens/voice/active_room_screen.dart`
- `lib/widgets/voice/incoming_invite_sheet.dart`
- `lib/widgets/voice/call_overlay.dart`
- `lib/widgets/voice/participant_avatar.dart` — with speaking indicator animation

Modified:
- App router — add voice room routes

**Verify**: Full user flow end-to-end: create room from UI, invite friend, friend sees invite, joins, both talk, leave cleanly.

### Phase E: Hardening
- Reconnection on network glitch (auto-retry ICE for 10s before giving up)
- Microphone permission handling (explain and link to settings on denial)
- iOS AVAudioSession configuration (`.playAndRecord` category)
- Android audio focus management
- Background lifecycle: leave room on iOS background; Android foreground service keeps call alive (requires Plan 14)
- Battery/thermal monitoring and warnings

## Known Limitations (v1)

1. **~30% of WAN peer pairs can't connect** — symmetric NAT / CGNAT / corporate firewalls. No TURN fallback. UI is honest about it.
2. **No voice over Tor** — Tor is signaling only. If peers have no direct IP path, voice is impossible between them.
3. **4-person cap** — full mesh only, no mixer.
4. **No background voice on iOS** — call ends on background (unless CallKit is pursued later).
5. **No push notifications for invites** — consistent with the rest of Finch. App must be open to receive invites.
6. **No audio recording** — by design, not limitation. Consistent with Finch's privacy philosophy.

## Key Existing Files to Modify

- `lib/models/event_kind.dart` — add kinds 10-13
- `lib/services/types.dart` — add voice-related types
- `lib/services/storage_service.dart` — voice room storage methods
- `lib/services/storage/database.dart` — migration adding tables
- `lib/services/storage/drift_storage_service.dart` — implement voice room storage
- `lib/services/crypto_service.dart` — reuse `deriveSharedKey` with `"finch-signaling-v1"` salt
- `lib/providers/service_providers.dart` — new providers
- `lib/server/http_server.dart` — WebSocket route
- `pubspec.yaml` — new dependencies
