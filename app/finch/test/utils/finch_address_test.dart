import 'dart:typed_data';

import 'package:finch/services/crypto/crockford_base32.dart';
import 'package:finch/utils/finch_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 32 bytes of 0x42 → deterministic 52-char Crockford base32 string.
  final pubkey = crockfordBase32Encode(Uint8List(32)..fillRange(0, 32, 0x42));

  test('finchAddressOf prepends finch://', () {
    expect(finchAddressOf(pubkey), 'finch://$pubkey');
  });

  test('pubkeyFromFinchAddress round-trips a valid address', () {
    expect(pubkeyFromFinchAddress(finchAddressOf(pubkey)), pubkey);
  });

  test('pubkeyFromFinchAddress trims whitespace', () {
    expect(pubkeyFromFinchAddress('  finch://$pubkey  '), pubkey);
  });

  test('pubkeyFromFinchAddress rejects the invite scheme', () {
    expect(
      pubkeyFromFinchAddress('finch://connect?card=AAAA'),
      isNull,
    );
  });

  test('pubkeyFromFinchAddress rejects wrong scheme', () {
    expect(pubkeyFromFinchAddress('https://$pubkey'), isNull);
    expect(pubkeyFromFinchAddress('finch:$pubkey'), isNull);
  });

  test('pubkeyFromFinchAddress rejects malformed pubkey', () {
    // Too short.
    expect(pubkeyFromFinchAddress('finch://abc'), isNull);
    // 'u' is not in the Crockford alphabet (skipped along with i/l/o).
    expect(pubkeyFromFinchAddress('finch://${'u' * 52}'), isNull);
  });

  test('pubkeyFromFinchAddress rejects URL with a path', () {
    expect(pubkeyFromFinchAddress('finch://$pubkey/extra'), isNull);
  });

  test('shortFinchAddress truncates with ellipsis', () {
    final short = shortFinchAddress(pubkey);
    expect(short.startsWith('finch://'), isTrue);
    expect(short.contains('…'), isTrue);
    expect(short.length, lessThan(finchAddressOf(pubkey).length));
  });
}
