import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:finch/models/models.dart';
import 'package:finch/services/crypto/crockford_base32.dart';
import 'package:finch/services/crypto/feed_key_ratchet.dart';
import 'package:finch/services/crypto/sodium_crypto_service.dart';
import 'package:finch/services/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Uint8List fromHex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

String hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

/// Loads `test/vectors/index.json` from the package. Works regardless of
/// the cwd `flutter test` is run from.
Map<String, dynamic> _loadVectors() {
  // When running from the package root, the cwd is the package root.
  final candidates = [
    'test/vectors/index.json',
    p.join(Directory.current.path, 'test/vectors/index.json'),
  ];
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) {
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('could not find test/vectors/index.json');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CryptoService crypto;
  late Map<String, dynamic> vectors;

  setUpAll(() async {
    crypto = await SodiumCryptoService.init();
    vectors = _loadVectors();
  });

  test('vector 1: keypair from fixed seed', () async {
    final v = vectors['keypair'] as Map<String, dynamic>;
    final seed = fromHex(v['seed_hex'] as String);
    final expectedPhrase = (v['recovery_phrase'] as List).cast<String>();
    final expectedPk = v['ed25519_public_key_hex'] as String;
    final expectedSk = v['ed25519_secret_key_hex'] as String;
    final expectedXpk = v['x25519_public_key_hex'] as String;
    final expectedXsk = v['x25519_secret_key_hex'] as String;

    final phrase = await crypto.deriveRecoveryPhrase(seed);
    expect(phrase, expectedPhrase);

    final kp = await crypto.recoverFromPhrase(phrase);
    expect(hex(kp.publicKey), expectedPk);
    expect(hex(kp.secretKey), expectedSk);

    expect(hex(crypto.ed25519ToX25519PublicKey(kp.publicKey)), expectedXpk);
    expect(hex(crypto.ed25519ToX25519SecretKey(kp.secretKey)), expectedXsk);
  });

  test('vector 2: event id from fixed fields', () async {
    final v = vectors['event_id'] as Map<String, dynamic>;
    final event = Event(
      version: v['version'] as String,
      id: '',
      pubkey: v['pubkey'] as String,
      createdAt: v['created_at'] as int,
      kind: EventKind.fromValue(v['kind'] as int),
      content: fromHex(v['content_hex'] as String),
      sig: Uint8List(0),
    );

    final idFieldsBytes = Uint8List.fromList(cbor.encode(event.toIdFields()));
    expect(hex(idFieldsBytes), v['id_fields_cbor_hex'] as String);

    final idHash = crypto.blake2b256(idFieldsBytes);
    expect(hex(idHash), v['id_bytes_hex'] as String);
    expect(crockfordBase32Encode(idHash), v['id_base32'] as String);
  });

  test('vector 3: event signature', () async {
    final v = vectors['event_sign'] as Map<String, dynamic>;
    final kpFixed = vectors['keypair'] as Map<String, dynamic>;
    final sk = fromHex(kpFixed['ed25519_secret_key_hex'] as String);
    final message = fromHex(v['signed_bytes_hex'] as String);
    final sig = crypto.sign(sk, message);
    expect(hex(sig), v['signature_hex'] as String);

    // And the signature must verify.
    final pk = fromHex(kpFixed['ed25519_public_key_hex'] as String);
    expect(crypto.verify(pk, message, sig), isTrue);
  });

  test('vector 4: feed key ratchet', () async {
    final v = vectors['ratchet'] as Map<String, dynamic>;
    final base = fromHex(v['base_key_hex'] as String);
    final epoch1 = ratchetFeedKey(base, crypto);
    final epoch2 = ratchetFeedKey(epoch1, crypto);
    expect(hex(epoch1), v['epoch_1_hex'] as String);
    expect(hex(epoch2), v['epoch_2_hex'] as String);
  });

  test('vector 5: event encryption with fixed nonce and key', () async {
    final v = vectors['event_encrypt'] as Map<String, dynamic>;
    final feedKey = fromHex(v['feed_key_hex'] as String);
    final nonce = fromHex(v['nonce_hex'] as String);
    final eventBytes = fromHex(v['event_bytes_hex'] as String);
    final expectedCt = v['ciphertext_hex'] as String;
    final ct = crypto.encrypt(eventBytes, nonce, feedKey);
    expect(hex(ct), expectedCt);

    // And the decryption round-trips.
    final pt = crypto.decrypt(ct, nonce, feedKey);
    expect(pt, eventBytes);
  });
}
