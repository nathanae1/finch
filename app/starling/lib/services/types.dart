import 'dart:typed_data';

class KeyPair {
  const KeyPair({required this.publicKey, required this.secretKey});
  final Uint8List publicKey; // 32 bytes
  final Uint8List secretKey; // 64 bytes (Ed25519 expanded)
}

class TorStatus {
  const TorStatus({
    required this.bootstrapPercent,
    required this.circuitCount,
    required this.isReady,
    this.onionAddress,
  });
  final int bootstrapPercent;
  final int circuitCount;
  final bool isReady;
  final String? onionAddress;
}

class LanPeer {
  const LanPeer({
    required this.pubkey,
    required this.host,
    required this.port,
  });
  final String pubkey;
  final String host;
  final int port;
}

class PeerConnection {
  const PeerConnection({
    required this.pubkey,
    required this.baseUrl,
    required this.transport,
  });
  final String pubkey;
  final String baseUrl;
  final PeerTransport transport;
}

enum PeerTransport { lan, libp2pDirect, relay, tor }

class Manifest {
  const Manifest({
    required this.pubkey,
    required this.events,
    required this.hasOlder,
    this.newFeedKey,
  });
  final String pubkey;
  final List<ManifestEntry> events;
  final bool hasOlder;
  // Plan 13: when present, the requester is being told about a feed-key
  // rotation by the remote peer. Decrypt with the X25519 DH shared key
  // derived against the peer's pubkey, then persist as `follow.feedKey`
  // and ack via `ack_rotation_at` on the next /manifest call.
  final RotatedFeedKeyDelivery? newFeedKey;
}

class ManifestEntry {
  const ManifestEntry({required this.id, required this.createdAt});
  final String id;
  final int createdAt;
}

/// Wire-level payload of an inline feed-key rotation in a manifest
/// response (Plan 13). Decrypted and applied by the syncing follower.
class RotatedFeedKeyDelivery {
  const RotatedFeedKeyDelivery({
    required this.encryptedFeedKey,
    required this.nonce,
    required this.createdAt,
  });
  final Uint8List encryptedFeedKey;
  final Uint8List nonce;
  final int createdAt;
}

class Identity {
  const Identity({
    required this.pubkey,
    required this.feedKey,
    this.feedKeyEpoch = 0,
    this.feedKeyValidFrom = 0,
    this.msgSeqCounter = 0,
    this.recoveryPhrase,
    required this.createdAt,
  });
  final String pubkey;
  final Uint8List feedKey;
  final int feedKeyEpoch;
  // Unix-seconds timestamp at which `feedKey` became the current key.
  // Identities created pre-Plan-13 backfill this to `createdAt` on migration.
  final int feedKeyValidFrom;
  // MegOLM-shaped per-message counter. Bumped under PublishLock for every
  // event we publish; reset to 0 when `feedKey` rotates. The currently
  // stored value is the next `msg_seq` to allocate.
  final int msgSeqCounter;
  final String? recoveryPhrase;
  final int createdAt;

  Identity copyWith({
    Uint8List? feedKey,
    int? feedKeyEpoch,
    int? feedKeyValidFrom,
    int? msgSeqCounter,
  }) =>
      Identity(
        pubkey: pubkey,
        feedKey: feedKey ?? this.feedKey,
        feedKeyEpoch: feedKeyEpoch ?? this.feedKeyEpoch,
        feedKeyValidFrom: feedKeyValidFrom ?? this.feedKeyValidFrom,
        msgSeqCounter: msgSeqCounter ?? this.msgSeqCounter,
        recoveryPhrase: recoveryPhrase,
        createdAt: createdAt,
      );
}

/// A retired feed key (Plan 13). `feedKey` was the current key during the
/// half-open window `[validFrom, validUntil)` and was rotated out at
/// `validUntil`. Used to decrypt own content (e.g. media files) that was
/// encrypted under this key before the rotation.
class RetiredFeedKey {
  const RetiredFeedKey({
    required this.feedKey,
    required this.feedKeyEpoch,
    required this.validFrom,
    required this.validUntil,
  });
  final Uint8List feedKey;
  final int feedKeyEpoch;
  final int validFrom;
  final int validUntil;
}

/// A wrapped feed key waiting to be delivered to a follower (Plan 13).
/// The plaintext (32-byte feed key) was encrypted with the X25519 DH
/// shared key derived against [targetPubkey] at the moment of rotation.
class PendingKeyDistribution {
  const PendingKeyDistribution({
    required this.targetPubkey,
    required this.encryptedFeedKey,
    required this.nonce,
    required this.createdAt,
  });
  final String targetPubkey;
  final Uint8List encryptedFeedKey;
  final Uint8List nonce;
  final int createdAt;
}

class Follow {
  const Follow({
    required this.pubkey,
    this.displayName,
    this.avatarHash,
    required this.connectionCard,
    required this.feedKey,
    this.feedKeyEpoch = 0,
    this.lastSyncedAt = 0,
    this.lastReceivedRotationAt = 0,
    this.lastDecryptFailureAt,
    this.status = 'active',
  });
  final String pubkey;
  final String? displayName;
  final String? avatarHash;
  final String connectionCard; // serialized JSON
  final Uint8List feedKey;
  final int feedKeyEpoch;
  final int lastSyncedAt;
  // Plan 13: `created_at` of the most recent rotated feed key we've
  // accepted from this peer. Sent back as `ack_rotation_at` on the next
  // /manifest call so the peer can mark the distribution as delivered.
  final int lastReceivedRotationAt;
  // Unix-second timestamp of the most recent decrypt failure on this
  // peer's content (event or media). Set when a stale-key signal lands;
  // cleared when a fresh rotation is applied. Drives the "Key" status
  // tile in connection settings.
  final int? lastDecryptFailureAt;
  final String status;

  Follow copyWith({
    Uint8List? feedKey,
    int? feedKeyEpoch,
    int? lastSyncedAt,
    int? lastReceivedRotationAt,
    int? lastDecryptFailureAt,
    bool clearLastDecryptFailureAt = false,
    String? status,
  }) =>
      Follow(
        pubkey: pubkey,
        displayName: displayName,
        avatarHash: avatarHash,
        connectionCard: connectionCard,
        feedKey: feedKey ?? this.feedKey,
        feedKeyEpoch: feedKeyEpoch ?? this.feedKeyEpoch,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        lastReceivedRotationAt:
            lastReceivedRotationAt ?? this.lastReceivedRotationAt,
        lastDecryptFailureAt: clearLastDecryptFailureAt
            ? null
            : (lastDecryptFailureAt ?? this.lastDecryptFailureAt),
        status: status ?? this.status,
      );
}

class FollowRequest {
  const FollowRequest({
    required this.pubkey,
    required this.payload,
    required this.createdAt,
    required this.requestTimestamp,
    this.status = 'pending',
  });
  final String pubkey;
  final Uint8List payload;
  // Local DB write time. For inbound rows: receive time. For outbound rows:
  // identical to requestTimestamp.
  final int createdAt;
  // Wire timestamp the requester signed into the outer CBOR. Used by both
  // sides to derive the same shared key for the handshake.
  final int requestTimestamp;
  final String status;
}

class CachedMedia {
  const CachedMedia({
    required this.hash,
    required this.path,
    required this.size,
    required this.lastAccessed,
  });
  final String hash;
  final String path;
  final int size;
  final int lastAccessed;
}

/// An EnvelopeItem whose `type` we don't recognize. Stored opaquely so we
/// can preserve and forward unknown items per the protocol-spec trust
/// model. v1 has only `type:"event"`, so this type carries no consumers
/// yet — it exists for forward compat (Plan 11 onward).
class UnknownEnvelopeItem {
  const UnknownEnvelopeItem({
    required this.sourcePubkey,
    required this.envelopeVersion,
    required this.type,
    required this.payload,
    this.extensions,
    required this.receivedAt,
  });
  final String sourcePubkey;
  final String envelopeVersion;
  final String type;
  final Uint8List payload;
  final Uint8List? extensions;
  final int receivedAt;
}

class QueuedEvent {
  const QueuedEvent({
    required this.id,
    required this.targetPubkey,
    required this.eventBlob,
    required this.createdAt,
    this.retryCount = 0,
  });
  final int id;
  final String targetPubkey;
  final Uint8List eventBlob;
  final int createdAt;
  final int retryCount;
}

// --- Signaling types (Plan 16 — Voice Chatrooms) ---

/// A persistent bidirectional signaling channel to a remote peer.
///
/// Wraps a WebSocket connection. Used for exchanging ephemeral signaling
/// messages (room invites, SDP offers/answers, ICE candidates).
abstract class SignalingChannel {
  /// The remote peer's Ed25519 public key.
  String get remotePubkey;

  /// The transport used for this channel.
  PeerTransport get transport;

  /// Send a raw CBOR-encoded message to the remote peer.
  /// The message should already be encrypted as an [EphemeralEncryptedEvent].
  Future<void> send(Uint8List data);

  /// Stream of raw inbound CBOR-encoded messages from the remote peer.
  Stream<Uint8List> get messages;

  /// Whether the underlying WebSocket is still open.
  bool get isOpen;

  /// Close this channel.
  Future<void> close();
}
