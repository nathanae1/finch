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

enum PeerTransport { lan, relay, tor }

class Manifest {
  const Manifest({
    required this.pubkey,
    required this.events,
    required this.hasOlder,
  });
  final String pubkey;
  final List<ManifestEntry> events;
  final bool hasOlder;
}

class ManifestEntry {
  const ManifestEntry({required this.id, required this.createdAt});
  final String id;
  final int createdAt;
}

class Identity {
  const Identity({
    required this.pubkey,
    required this.feedKey,
    this.recoveryPhrase,
    required this.createdAt,
  });
  final String pubkey;
  final Uint8List feedKey;
  final String? recoveryPhrase;
  final int createdAt;
}

class Follow {
  const Follow({
    required this.pubkey,
    this.displayName,
    this.avatarHash,
    required this.connectionCard,
    required this.feedKey,
    this.lastSyncedAt = 0,
    this.status = 'active',
  });
  final String pubkey;
  final String? displayName;
  final String? avatarHash;
  final String connectionCard; // serialized JSON
  final Uint8List feedKey;
  final int lastSyncedAt;
  final String status;
}

class FollowRequest {
  const FollowRequest({
    required this.pubkey,
    required this.payload,
    required this.createdAt,
    this.status = 'pending',
  });
  final String pubkey;
  final Uint8List payload;
  final int createdAt;
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
