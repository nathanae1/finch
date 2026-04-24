import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:collection/collection.dart';

class EncryptedEvent {
  const EncryptedEvent({
    required this.pubkey,
    required this.createdAt,
    required this.epoch,
    required this.nonce,
    required this.payload,
  });

  final String pubkey;
  final int createdAt;
  final int epoch; // feed key epoch number
  final Uint8List nonce; // 24 bytes
  final Uint8List payload;

  Map<String, dynamic> toMap() => {
        'pubkey': pubkey,
        'created_at': createdAt,
        'epoch': epoch,
        'nonce': nonce,
        'payload': payload,
      };

  Uint8List toBytes() => Uint8List.fromList(cbor.encode(toMap()));

  static EncryptedEvent fromMap(Map<dynamic, dynamic> map) => EncryptedEvent(
        pubkey: map['pubkey'] as String,
        createdAt: map['created_at'] as int,
        epoch: map['epoch'] as int,
        nonce: _toUint8List(map['nonce']),
        payload: _toUint8List(map['payload']),
      );

  static EncryptedEvent fromBytes(Uint8List bytes) =>
      fromMap(cbor.decode(bytes) as Map<dynamic, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptedEvent &&
          pubkey == other.pubkey &&
          createdAt == other.createdAt &&
          epoch == other.epoch &&
          const ListEquality<int>().equals(nonce, other.nonce) &&
          const ListEquality<int>().equals(payload, other.payload);

  @override
  int get hashCode => Object.hash(pubkey, createdAt, epoch);

  @override
  String toString() =>
      'EncryptedEvent(pubkey: $pubkey, createdAt: $createdAt, '
      'epoch: $epoch, payloadSize: ${payload.length})';
}

Uint8List _toUint8List(dynamic value) {
  if (value is Uint8List) return value;
  if (value is List) return Uint8List.fromList(value.cast<int>());
  throw ArgumentError('Expected bytes, got ${value.runtimeType}');
}
