import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import '../../models/encrypted_event.dart';
import '../../models/envelope.dart';
import '../../services/clock.dart';
import '../../services/content_key_service.dart';
import '../../services/storage_service.dart';
import '../../services/types.dart';

/// `POST /events` — receives a CBOR-encoded `Envelope` of pushed events
/// from a follower, decrypts each item with the source follow's feed key,
/// and stores the plaintext locally.
///
/// Authentication is by feed-key possession: each `EnvelopeItem(type:'event')`
/// carries an `EncryptedEvent` that names its author pubkey. We accept the
/// item only if (a) we follow that pubkey (so we have their feed key), and
/// (b) decryption succeeds (which itself verifies the inner Ed25519
/// signature). Items that fail either check are dropped silently — the
/// response is always 202 so we don't leak which pubkeys we follow.
Handler eventsPushHandler({
  required StorageService storage,
  required ContentKeyService contentKey,
  required Clock clock,
}) {
  return (Request request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
    }
    final bodyBytes = builder.toBytes();
    if (bodyBytes.isEmpty) {
      return Response(400, body: 'empty body');
    }

    final Envelope envelope;
    try {
      envelope = Envelope.fromBytes(bodyBytes);
    } catch (e) {
      return Response(400, body: 'invalid envelope cbor');
    }

    var accepted = 0;
    var rejected = 0;
    for (final item in envelope.items) {
      if (item.type != 'event') {
        // Forward-compat: store unknown types; later plans may consume.
        await storage.saveUnknownEnvelopeItem(
          UnknownEnvelopeItem(
            sourcePubkey: '',
            envelopeVersion: envelope.version,
            type: item.type,
            payload: item.payload,
            receivedAt: clock.nowUnixSeconds(),
          ),
        );
        continue;
      }
      try {
        final encrypted = EncryptedEvent.fromBytes(item.payload);
        final follow = await storage.getFollow(encrypted.pubkey);
        if (follow == null) {
          // Sender pubkey isn't on our follows list — silently drop.
          rejected++;
          continue;
        }
        // Mirror sync_engine: msgSeq is local-only metadata excluded from
        // wire serialization, so the decrypted Event has it null. Carry
        // the wire-format msgSeq through so media decryption can later
        // re-derive the per-message AEAD key without re-fetching.
        final decrypted = contentKey.decryptEvent(encrypted, follow.feedKey);
        final plain = decrypted.copyWith(msgSeq: encrypted.msgSeq);
        await storage.saveEvent(plain);
        accepted++;
      } catch (e) {
        developer.log(
          'rejected pushed event: $e',
          name: 'events_push_handler',
        );
        rejected++;
      }
    }

    developer.log(
      'POST /events accepted=$accepted rejected=$rejected',
      name: 'events_push_handler',
    );
    return Response(202, body: '');
  };
}
