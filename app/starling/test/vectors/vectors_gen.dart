// ignore_for_file: avoid_print

// One-shot vector generator. Run this manually to regenerate the
// canonical test vectors that pin the protocol against accidental changes.
//
// Usage:
//   flutter test test/vectors/vectors_gen.dart
//
// This "test" prints a JSON index to stdout. Copy-paste the output into
// `test/vectors/index.json`, then run `vectors_test.dart` to assert the
// pinned values.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:starling/models/models.dart';
import 'package:starling/services/crypto/crockford_base32.dart';
import 'package:starling/services/crypto/feed_key_ratchet.dart';
import 'package:starling/services/crypto/sodium_crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Uint8List fromHex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate protocol test vectors', () async {
    final crypto = await SodiumCryptoService.init();

    // Vector 1: keypair from fixed seed.
    final seed = fromHex(
      '000102030405060708090a0b0c0d0e0f'
      '101112131415161718191a1b1c1d1e1f',
    );
    final phrase = await crypto.deriveRecoveryPhrase(seed);
    final kp = await crypto.recoverFromPhrase(phrase);
    final xpk = crypto.ed25519ToX25519PublicKey(kp.publicKey);
    final xsk = crypto.ed25519ToX25519SecretKey(kp.secretKey);

    // Vector 2: event id for a fixed event.
    final event = Event(
      version: '2026-03-24',
      id: '',
      pubkey: crockfordBase32Encode(kp.publicKey),
      createdAt: 1_700_000_000,
      kind: EventKind.fromValue(1),
      content: Uint8List.fromList('hello starling'.codeUnits),
      sig: Uint8List(0),
    );
    final idFieldsBytes = Uint8List.fromList(cbor.encode(event.toIdFields()));
    final idHash = crypto.blake2b256(idFieldsBytes);
    final eventId = crockfordBase32Encode(idHash);

    // Vector 3: event signature over id bytes.
    final sig = crypto.sign(kp.secretKey, idHash);

    // Vector 4: feed key ratchet, fixed base key.
    final baseKey = fromHex(
      'ff' * 32,
    );
    final epoch1 = ratchetFeedKey(baseKey, crypto);
    final epoch2 = ratchetFeedKey(epoch1, crypto);

    // Vector 5: event encryption with fixed key + nonce.
    final feedKey = fromHex('a1' * 32);
    final nonce = fromHex('b2' * 24);
    final signedEvent = event.copyWith(id: eventId, sig: sig);
    final ciphertext = crypto.encrypt(signedEvent.toBytes(), nonce, feedKey);

    final vectors = {
      'keypair': {
        'seed_hex': hex(seed),
        'recovery_phrase': phrase,
        'ed25519_public_key_hex': hex(kp.publicKey),
        'ed25519_secret_key_hex': hex(kp.secretKey),
        'x25519_public_key_hex': hex(xpk),
        'x25519_secret_key_hex': hex(xsk),
      },
      'event_id': {
        'version': event.version,
        'pubkey': event.pubkey,
        'created_at': event.createdAt,
        'kind': event.kind.value,
        'content_hex': hex(event.content),
        'id_fields_cbor_hex': hex(idFieldsBytes),
        'id_bytes_hex': hex(idHash),
        'id_base32': eventId,
      },
      'event_sign': {
        'signer_pubkey_hex': hex(kp.publicKey),
        'signed_bytes_hex': hex(idHash),
        'signature_hex': hex(sig),
      },
      'ratchet': {
        'base_key_hex': hex(baseKey),
        'epoch_1_hex': hex(epoch1),
        'epoch_2_hex': hex(epoch2),
      },
      'event_encrypt': {
        'feed_key_hex': hex(feedKey),
        'nonce_hex': hex(nonce),
        'event_bytes_hex': hex(signedEvent.toBytes()),
        'ciphertext_hex': hex(ciphertext),
      },
    };

    print('\n===== BEGIN VECTOR JSON =====');
    print(const JsonEncoder.withIndent('  ').convert(vectors));
    print('===== END VECTOR JSON =====\n');
  });
}
