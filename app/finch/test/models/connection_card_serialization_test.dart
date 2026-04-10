import 'package:cbor/simple.dart';
import 'package:finch/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectionCard CBOR serialization', () {
    test('round-trips with endpoints', () {
      const card = ConnectionCard(
        pubkey: 'test-pubkey-123',
        endpoints: [
          Endpoint(type: 'onion', address: 'abc123.onion'),
          Endpoint(type: 'relay', address: 'https://relay.example.com'),
        ],
      );
      final decoded = ConnectionCard.fromBytes(card.toBytes());
      expect(decoded, equals(card));
    });

    test('round-trips with empty endpoints', () {
      const card = ConnectionCard(pubkey: 'test-pubkey-456');
      final decoded = ConnectionCard.fromBytes(card.toBytes());
      expect(decoded.pubkey, equals('test-pubkey-456'));
      expect(decoded.endpoints, isEmpty);
      expect(decoded, equals(card));
    });

    test('Endpoint round-trips through CBOR', () {
      const endpoint = Endpoint(type: 'onion', address: 'xyz.onion');
      final bytes = cbor.encode(endpoint.toMap());
      final decoded =
          Endpoint.fromMap(cbor.decode(bytes) as Map<dynamic, dynamic>);
      expect(decoded, equals(endpoint));
    });

    test('both onion and relay types preserved', () {
      const card = ConnectionCard(
        pubkey: 'pk',
        endpoints: [
          Endpoint(type: 'onion', address: 'abc.onion'),
          Endpoint(type: 'relay', address: 'https://r.example.com'),
        ],
      );
      final decoded = ConnectionCard.fromBytes(card.toBytes());
      expect(decoded.endpoints[0].type, equals('onion'));
      expect(decoded.endpoints[1].type, equals('relay'));
      expect(decoded.endpoints[0].address, equals('abc.onion'));
      expect(decoded.endpoints[1].address, equals('https://r.example.com'));
    });
  });
}
