/// Starling protocol version. Included in every event's `version` field and in
/// the event ID hash so downgrade attacks (forging a v2 event but claiming v1)
/// cannot replace a valid signed event with an older one.
///
/// Date-based, bumped when the CBOR event schema changes in a non-backward-
/// compatible way.
const kStarlingProtocolVersion = '2026-04-28';
