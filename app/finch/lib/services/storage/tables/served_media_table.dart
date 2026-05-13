import 'package:drift/drift.dart';

/// Encrypted media blobs pushed by the Owner that the Relay serves at
/// `GET /media/<hash>`.
///
/// The Relay never decrypts; `path` points to the on-disk file containing
/// the same `nonce || XChaCha20-Poly1305(...)` bytes the Owner uploaded.
/// `hash` is the BLAKE2b-256 of the plaintext blob, matching the
/// `MediaRef.hash` inside the parent Event.
class ServedMediaEntries extends Table {
  TextColumn get hash => text()();
  IntColumn get size => integer()();
  IntColumn get createdAt => integer()();
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {hash};
}
