import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:collection/collection.dart';

import 'event_kind.dart';
import 'media_ref.dart';

class Event {
  const Event({
    required this.version,
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    this.ref,
    required this.content,
    this.media = const [],
    required this.sig,
  });

  final String version;
  final String id;
  final String pubkey;
  final int createdAt;
  final EventKind kind;
  final String? ref;
  final Uint8List content;
  final List<MediaRef> media;
  final Uint8List sig;

  Map<String, dynamic> toMap() => {
        'version': version,
        'id': id,
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind.value,
        if (ref != null) 'ref': ref,
        'content': content,
        'media': media.map((m) => m.toMap()).toList(),
        'sig': sig,
      };

  /// Fields used for ID computation (excludes id and sig).
  Map<String, dynamic> toIdFields() => {
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind.value,
        'content': content,
      };

  Uint8List toBytes() => Uint8List.fromList(cbor.encode(toMap()));

  static Event fromMap(Map<dynamic, dynamic> map) => Event(
        version: map['version'] as String,
        id: map['id'] as String,
        pubkey: map['pubkey'] as String,
        createdAt: map['created_at'] as int,
        kind: EventKind.fromValue(map['kind'] as int),
        ref: map['ref'] as String?,
        content: _toUint8List(map['content']),
        media: (map['media'] as List<dynamic>)
            .map(
              (item) => MediaRef.fromMap(item as Map<dynamic, dynamic>),
            )
            .toList(),
        sig: _toUint8List(map['sig']),
      );

  static Event fromBytes(Uint8List bytes) =>
      fromMap(cbor.decode(bytes) as Map<dynamic, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          version == other.version &&
          id == other.id &&
          pubkey == other.pubkey &&
          createdAt == other.createdAt &&
          kind == other.kind &&
          ref == other.ref &&
          const ListEquality<int>().equals(content, other.content) &&
          const ListEquality<MediaRef>().equals(media, other.media) &&
          const ListEquality<int>().equals(sig, other.sig);

  @override
  int get hashCode => Object.hash(version, id, pubkey, createdAt, kind, ref);

  @override
  String toString() =>
      'Event(id: $id, pubkey: $pubkey, kind: $kind, createdAt: $createdAt)';

  Event copyWith({
    String? version,
    String? id,
    String? pubkey,
    int? createdAt,
    EventKind? kind,
    String? ref,
    Uint8List? content,
    List<MediaRef>? media,
    Uint8List? sig,
  }) =>
      Event(
        version: version ?? this.version,
        id: id ?? this.id,
        pubkey: pubkey ?? this.pubkey,
        createdAt: createdAt ?? this.createdAt,
        kind: kind ?? this.kind,
        ref: ref ?? this.ref,
        content: content ?? this.content,
        media: media ?? this.media,
        sig: sig ?? this.sig,
      );
}

// CBOR decode may return List<int> instead of Uint8List for byte strings.
Uint8List _toUint8List(dynamic value) {
  if (value is Uint8List) return value;
  if (value is List) return Uint8List.fromList(value.cast<int>());
  throw ArgumentError('Expected bytes, got ${value.runtimeType}');
}
