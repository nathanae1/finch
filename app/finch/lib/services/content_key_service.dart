import 'dart:typed_data';

import '../models/models.dart';

/// Feed key management, epoch ratchet, and composed crypto operations.
///
/// Uses [CryptoService] for primitives. This is the layer that evolves
/// when MLS arrives — it gets a second implementation, not a rewrite.
///
/// v1 implementation: pairwise (encrypt once with feed key, key shared
/// pairwise with each follower via X25519 DH).
abstract class ContentKeyService {
  // --- Feed key lifecycle ---

  Future<Uint8List> generateFeedKey();

  /// Advance the feed key to the next epoch.
  /// `nextKey = BLAKE2b-256(currentKey || "finch-ratchet-v1")`
  Uint8List advanceEpoch(Uint8List currentKey);

  // --- Event encryption (sign-then-encrypt / decrypt-then-verify) ---

  EncryptedEvent encryptEvent(Event event, Uint8List epochKey, int epoch);

  Event decryptEvent(EncryptedEvent encryptedEvent, Uint8List epochKey);

  // --- Feed key wrapping (for follower key exchange) ---

  Uint8List encryptFeedKey(Uint8List feedKey, Uint8List sharedKey);

  Uint8List decryptFeedKey(Uint8List encryptedFeedKey, Uint8List sharedKey);

  // --- Event ID ---

  String computeEventId(Event event);

  // --- Publish pipeline ---

  /// Encrypt an event for the given audience. For [Audience.broadcast],
  /// signs and encrypts with the current feed key.
  EncryptedEvent encryptForAudience(Event event, Audience audience);

  /// Sign and encrypt an event for the given audience, returning both the
  /// signed plaintext (for local storage) and the encrypted wire form (for
  /// the outbound queue / network). Callers that only need the wire form
  /// can use [encryptForAudience] instead.
  ({Event signed, EncryptedEvent encrypted}) signAndEncryptForAudience(
    Event event,
    Audience audience,
  );
}
