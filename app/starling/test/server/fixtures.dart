import 'dart:typed_data';

import 'package:starling/models/models.dart';
import 'package:starling/models/protocol_version.dart';
import 'package:starling/services/types.dart';

/// Builds an [Identity] with deterministic feed-key bytes for tests.
Identity buildIdentity({
  String pubkey = 'TESTPUBKEY01234567890123456789012345',
  int feedKeyEpoch = 0,
  int createdAt = 1000,
}) {
  return Identity(
    pubkey: pubkey,
    feedKey: Uint8List.fromList(List.filled(32, 0xAA)),
    feedKeyEpoch: feedKeyEpoch,
    createdAt: createdAt,
  );
}

/// Builds a signed-looking [Event] suitable for storage round-trips. The
/// signature is a sentinel (`0xBB` ×64); these tests don't verify it.
Event buildEvent({
  required String id,
  String pubkey = 'TESTPUBKEY01234567890123456789012345',
  int createdAt = 1000,
  EventKind kind = EventKind.post,
  String content = 'hello',
}) {
  return Event(
    version: kStarlingProtocolVersion,
    id: id,
    pubkey: pubkey,
    createdAt: createdAt,
    kind: kind,
    content: Uint8List.fromList(content.codeUnits),
    sig: Uint8List.fromList(List.filled(64, 0xBB)),
  );
}
