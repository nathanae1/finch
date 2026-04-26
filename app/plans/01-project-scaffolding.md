# Plan 01: Project Scaffolding & Service Interfaces

## Dependencies
None (first plan)

## Scope

Bootstrap the Flutter project with the foundational structure everything else builds on.

### Project setup
- `flutter create` inside `app/` with package name `dev.finch.app`
- Minimum SDK: iOS 26+, Android API 26+
- Directory structure:
  ```
  lib/
    main.dart
    models/
    services/
      mocks/
    providers/
    screens/
    widgets/
    server/
    sync/
  test/
  ```

### Abstract service interfaces
Define the contracts that all native interop hides behind:

- **`CryptoService`** — keypair generation, signing, verification, symmetric encryption/decryption, hashing, random bytes, Ed25519↔X25519 key conversion. Narrow interface covering crypto primitives only — no group key or feed key logic.
- **`ContentKeyService`** — feed key generation, feed key ratchet (epoch advancement), feed key encryption/decryption for followers, audience resolution. Uses `CryptoService` for primitives. Separated from `CryptoService` so group key management (pairwise today, MLS later) can evolve independently of crypto primitives.
- **`StorageService`** — event CRUD, follow CRUD, media cache, identity, outbound queue, retention
- **`TorService`** — onion service lifecycle, outbound Tor connections, .onion address persistence, status
- **`NetworkService`** — peer discovery, connection resolution (LAN/relay/Tor), HTTP client for peer endpoints
- **`Clock`** — injectable time source. Production: `DateTime.now()`. Tests: controllable. Every timestamp in crypto, sync, and event creation goes through this. Prevents clock-skew bugs and enables deterministic testing.

### Mock implementations
In-memory mock for each service interface. Used for testing and initial UI development before native FFI is wired up. Includes `MockClock` for deterministic time in tests.

### Models
Dart data classes with CBOR serialization. CBOR decoders MUST preserve unknown fields on decode, not drop them — this prevents old clients from silently stripping data added by newer protocol versions.

- `Event` — version, id, pubkey, created_at, kind, ref, content, media, extensions, sig. The `extensions` field is a `Map<String, Uint8List>` (empty map when no extensions). It is included in the ID hash and therefore inside the signature (see protocol spec trust model).
- `EncryptedEvent` — pubkey, created_at, epoch, nonce, payload
- `Envelope` — version, items (list of `EnvelopeItem`), extensions. The transport unit — all sync and push operations move Envelopes, not bare EncryptedEvents. The Envelope itself is untrusted; integrity is per-item.
- `EnvelopeItem` — type (string), payload (bytes), extensions. Type is an open enum: `"event"` for v1. Unknown types are preserved and forwarded, not dropped. See protocol spec for full trust model.
- `Audience` — enum-like type representing who content is encrypted for. v1 has one variant: `broadcast` (encrypt with feed key, key shared pairwise with each follower). Future: `group` (MLS). The publish pipeline uses `Audience` to determine which `ContentKeyService` mode to use.
- `MediaRef` — hash, mime_type, size
- `ConnectionCard` — pubkey, endpoints list, capabilities list. `capabilities` defaults to `["pairwise-v1"]` for v1 clients.
- Event kind enum: open integer enum. Defined kinds: post(1), profile(2), followList(3), comment(4), like(5), delete(6). Clients MUST store and sync unknown kinds without crashing. Unknown kinds are not rendered in UI. See protocol spec for reserved ranges.

### Riverpod setup
- `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` dependencies
- `build_runner` configured for code generation
- `ProviderScope` wrapping `MaterialApp` in main.dart
- Service providers for each interface (wired to mocks initially)

### Dependencies in pubspec.yaml
Declare all Phase 1 deps even if unused yet:
- `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
- `drift`, `sqlcipher_flutter_libs`, `sqlite3_flutter_libs`
- `shelf`, `shelf_router`
- `cbor`
- `qr_flutter` (QR rendering). QR scanning is a bespoke native platform channel — see Plan 08.
- `multicast_dns`
- `image`
- `flutter_secure_storage`
- `path_provider`
- `build_runner`, `riverpod_lint` (dev)

### Linting
- `analysis_options.yaml` with strict rules
- `riverpod_lint` for provider correctness

## Files created
- `app/finch/` — Flutter project root
- `lib/services/crypto_service.dart` — narrow crypto primitives interface
- `lib/services/content_key_service.dart` — feed key management, audience resolution, encryption-for-recipients
- `lib/services/storage_service.dart`
- `lib/services/tor_service.dart`
- `lib/services/network_service.dart`
- `lib/services/clock.dart` — injectable time source interface + production `SystemClock`
- `lib/services/mocks/mock_crypto_service.dart`
- `lib/services/mocks/mock_content_key_service.dart`
- `lib/services/mocks/mock_storage_service.dart`
- `lib/services/mocks/mock_tor_service.dart`
- `lib/services/mocks/mock_network_service.dart`
- `lib/services/mocks/mock_clock.dart` — controllable clock for deterministic tests
- `lib/models/event.dart` — includes extensions field
- `lib/models/encrypted_event.dart` — includes epoch field
- `lib/models/envelope.dart` — Envelope + EnvelopeItem types
- `lib/models/audience.dart` — Audience type (broadcast for v1)
- `lib/models/media_ref.dart`
- `lib/models/connection_card.dart` — includes capabilities field
- `lib/models/event_kind.dart` — open integer enum with reserved ranges
- `lib/providers/service_providers.dart`
- `lib/main.dart`
- `test/models/event_serialization_test.dart`
- `test/models/envelope_serialization_test.dart`

## Verification
- `flutter analyze` — zero issues
- `flutter test` — passes (model serialization round-trips)
- App builds and launches on iOS simulator and Android emulator
- Mock services injectable and swappable via Riverpod overrides
- Event model round-trips through CBOR: create → serialize → deserialize → fields match
- Event with extensions round-trips correctly: extensions preserved, included in ID hash
- Envelope round-trips through CBOR: create with EnvelopeItems → serialize → deserialize → items and extensions preserved
- Unknown CBOR fields preserved on decode (not silently dropped)
- Unknown event kinds stored without error
- Unknown EnvelopeItem types preserved without error
- ConnectionCard includes capabilities field, defaults to `["pairwise-v1"]`
- Clock injectable: MockClock produces deterministic timestamps in tests

## Key decisions
- Package name `dev.finch.app` — affects keychain access group, deep link scheme, mDNS service name
- iOS 26+ / Android API 26+ — modern crypto and keychain APIs
- All service interfaces are abstract classes, not mixins or extension types
- CryptoService is narrow (primitives only). Group key management (feed keys, ratchet, audience) lives in ContentKeyService, which uses CryptoService. This keeps crypto primitives stable forever and puts volatile group-messaging design in a layer that can have multiple implementations (pairwise today, MLS later).
- Event kind is an open integer enum, not a closed Dart enum. Unknown kinds are stored/synced/forwarded, not rendered. This allows protocol evolution without lockstep upgrades.
- Clock is injected everywhere timestamps are created or compared. No bare `DateTime.now()` in service or sync code.
- CBOR serialization preserves unknown fields on decode. This prevents old clients from stripping data they don't understand.
- Envelope is the transport unit, not EncryptedEvent. The Envelope is untrusted — integrity is per-item. See protocol spec for trust model.

## Risks
- Getting the abstract interfaces right is critical. Under-specifying them means refactoring every downstream plan. Spend time here — read the protocol spec and app spec carefully before finalizing method signatures.
- Riverpod code generation adds a build step. Establish the `build_runner` workflow early so it doesn't slow down later plans.
