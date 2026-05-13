import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:shelf/shelf.dart';

import '../../models/encrypted_event.dart';
import '../../services/storage/daos/relay_dao.dart';
import '../../services/storage/database.dart';

/// `POST /events` (Relay mode) — receives encrypted events from the
/// paired Owner and stores them verbatim.
///
/// Body format (CBOR map):
/// ```
/// {
///   items: [
///     { id: text, payload: bytes }, // payload is full EncryptedEvent CBOR
///     ...
///   ]
/// }
/// ```
///
/// `id` is the plaintext Event id the Owner computed before encrypting.
/// The Relay can't derive it (it has no Feed key) so the Owner sends it
/// alongside the ciphertext; it's used as the primary key and echoed in
/// `/manifest` responses to match the social-mode wire format.
///
/// This handler is mounted **behind** `ownerSignatureMiddleware`; by
/// the time it runs, the body has already been authenticated as the
/// Owner's. The handler does NOT decrypt — it has no Feed key. It only
/// parses the EncryptedEvent header (`pubkey`, `created_at`, `msg_seq`,
/// `nonce`) so `/manifest` and `/events` queries can do plaintext
/// timestamp filtering without touching the ciphertext.
///
/// Returns 202 on partial success too — the response body counts
/// accepted vs rejected items so the Owner can replay rejected ones on
/// the next push cycle.
Handler relayEventsPushHandler({required RelayDao dao}) {
  return (Request request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
    }
    final bodyBytes = builder.toBytes();
    if (bodyBytes.isEmpty) {
      return Response(400, body: 'empty body');
    }

    final dynamic raw;
    try {
      raw = cbor.decode(bodyBytes);
    } catch (_) {
      return Response(400, body: 'invalid cbor');
    }
    if (raw is! Map) {
      return Response(400, body: 'body must be a cbor map');
    }
    final items = raw['items'];
    if (items is! List) {
      return Response(400, body: '`items` must be a list');
    }

    var accepted = 0;
    var rejected = 0;
    for (final item in items) {
      if (item is! Map) {
        rejected++;
        continue;
      }
      final id = item['id'];
      final payload = item['payload'];
      if (id is! String || payload is! List) {
        rejected++;
        continue;
      }
      final payloadBytes = Uint8List.fromList(payload.cast<int>());

      final EncryptedEvent encrypted;
      try {
        encrypted = EncryptedEvent.fromBytes(payloadBytes);
      } catch (_) {
        rejected++;
        continue;
      }

      try {
        await dao.writeServedEvent(
          ServedEventEntriesCompanion.insert(
            id: id,
            pubkey: encrypted.pubkey,
            createdAt: encrypted.createdAt,
            msgSeq: encrypted.msgSeq,
            nonce: encrypted.nonce,
            payload: payloadBytes,
          ),
        );
        accepted++;
      } catch (e) {
        developer.log(
          'served_event write failed: $e',
          name: 'relay_events_push',
        );
        rejected++;
      }
    }

    developer.log(
      'relay POST /events accepted=$accepted rejected=$rejected',
      name: 'relay_events_push',
    );
    final responseBody = Uint8List.fromList(cbor.encode(<String, dynamic>{
      'accepted': accepted,
      'rejected': rejected,
    }));
    return Response(
      202,
      body: responseBody,
      headers: const {'content-type': 'application/cbor'},
    );
  };
}
