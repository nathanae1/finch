import 'package:drift/drift.dart';

/// EncryptedEvent blobs pushed by the Owner that the Relay serves
/// verbatim to Followers.
///
/// The Relay does NOT decrypt — it has no Feed key. The `payload`
/// column holds the raw `XChaCha20-Poly1305` ciphertext authored by the
/// Owner. `pubkey`, `createdAt`, `msgSeq`, and `nonce` are the plaintext
/// header fields the Owner attached so the Relay can answer
/// `/manifest` and `/events` queries without decrypting.
///
/// `id` is the plaintext Event id (BLAKE2b-256 over the inner Event
/// fields, Crockford base32) — the Relay can't derive this from the
/// ciphertext, so the Owner sends it alongside the encrypted payload in
/// the `POST /events` body. It serves as the primary key and the value
/// returned in `/manifest` responses, matching the social-mode wire
/// format the Follower already understands.
///
/// `pubkey` is always the singleton Owner from
/// `RelayPairedOwnerEntries` — stored here only so `/events` responses
/// can echo it cheaply without a join.
class ServedEventEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pubkey => text()();
  IntColumn get createdAt => integer()();
  IntColumn get msgSeq => integer()();
  BlobColumn get nonce => blob()();
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
