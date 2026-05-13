import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:shelf/shelf.dart';

import '../../relay/services/pairing_service.dart';

/// `POST /pair` — Relay-only handshake endpoint.
///
/// Consumes a single-use pairing token (issued by [PairingService]) and
/// records the claimant as the Relay's `paired_owner` on success.
/// Returns a CBOR `{ relay_onion, relay_id }` body that the phone uses
/// to label the Relay in its UI and persist the pairing.
///
/// Status codes track [PairingOutcome]:
/// - 200 + body on success
/// - 401 on token mismatch or invalid signature
/// - 409 on a token that's already been consumed
/// - 410 on an expired or absent token
///
/// The handler is unauthenticated by design — the pairing token IS the
/// auth, gated by single-use + TTL + onion-binding inside the signed
/// claim. After this returns 200 the owner-signature middleware takes
/// over for all subsequent owner-only writes.
Handler relayPairHandler({
  required PairingService pairingService,
  required String Function() relayOnion,
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

    final PairingClaim claim;
    try {
      claim = PairingClaim.fromCbor(bodyBytes);
    } on FormatException catch (e) {
      return Response(400, body: e.message);
    } catch (_) {
      return Response(400, body: 'invalid pairing claim');
    }

    final outcome = await pairingService.consumeClaim(claim);
    switch (outcome) {
      case PairingOutcome.success:
        final relayId = await pairingService.computeRelayId(claim.ownerPubkey);
        final body = Uint8List.fromList(cbor.encode(<String, dynamic>{
          'relay_onion': relayOnion(),
          'relay_id': relayId,
        }));
        return Response.ok(
          body,
          headers: const {'content-type': 'application/cbor'},
        );
      case PairingOutcome.tokenAlreadyConsumed:
        return Response(409, body: 'pairing token already consumed');
      case PairingOutcome.tokenExpired:
      case PairingOutcome.noActiveToken:
        return Response(410, body: 'pairing token expired');
      case PairingOutcome.tokenMismatch:
        return Response(401, body: 'pairing token mismatch');
      case PairingOutcome.signatureInvalid:
        return Response(401, body: 'invalid pairing signature');
    }
  };
}
