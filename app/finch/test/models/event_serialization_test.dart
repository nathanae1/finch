import 'dart:typed_data';

import 'package:finch/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event makeEvent({
    String? ref,
    List<MediaRef> media = const [],
  }) =>
      Event(
        version: '2026-03-24',
        id: 'test-id-123',
        pubkey: 'test-pubkey-abc',
        createdAt: 1711324800,
        kind: EventKind.post,
        ref: ref,
        content: Uint8List.fromList([72, 101, 108, 108, 111]), // "Hello"
        media: media,
        sig: Uint8List.fromList(List.filled(64, 0xFF)),
      );

  group('Event CBOR serialization', () {
    test('round-trips through bytes', () {
      final event = makeEvent();
      final bytes = event.toBytes();
      final decoded = Event.fromBytes(bytes);
      expect(decoded, equals(event));
    });

    test('preserves non-null ref', () {
      final event = makeEvent(ref: 'referenced-event-id');
      final decoded = Event.fromBytes(event.toBytes());
      expect(decoded.ref, equals('referenced-event-id'));
    });

    test('preserves null ref', () {
      final event = makeEvent();
      final decoded = Event.fromBytes(event.toBytes());
      expect(decoded.ref, isNull);
    });

    test('preserves media list with entries', () {
      final event = makeEvent(
        media: [
          const MediaRef(
            hash: 'abc123',
            mimeType: 'image/jpeg',
            size: 1024,
          ),
          const MediaRef(
            hash: 'def456',
            mimeType: 'image/png',
            size: 2048,
          ),
        ],
      );
      final decoded = Event.fromBytes(event.toBytes());
      expect(decoded.media, hasLength(2));
      expect(decoded.media[0].hash, equals('abc123'));
      expect(decoded.media[1].mimeType, equals('image/png'));
    });

    test('preserves empty media list', () {
      final event = makeEvent();
      final decoded = Event.fromBytes(event.toBytes());
      expect(decoded.media, isEmpty);
    });

    test('toIdFields only contains pubkey, created_at, kind, content', () {
      final event = makeEvent(ref: 'some-ref');
      final idFields = event.toIdFields();
      expect(idFields.keys.toSet(), equals({'pubkey', 'created_at', 'kind', 'content'}));
      expect(idFields['pubkey'], equals('test-pubkey-abc'));
      expect(idFields['created_at'], equals(1711324800));
      expect(idFields['kind'], equals(EventKind.post.value));
    });

    test('all EventKind values round-trip', () {
      for (final kind in EventKind.values) {
        expect(EventKind.fromValue(kind.value), equals(kind));
      }
    });
  });
}
