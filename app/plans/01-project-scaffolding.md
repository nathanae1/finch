# Plan 01: Project Scaffolding & Service Interfaces

## Dependencies
None (first plan)

## Scope

Bootstrap the Flutter project with the foundational structure everything else builds on.

### Project setup
- `flutter create` inside `app/` with package name `dev.finch.app`
- Minimum SDK: iOS 17+, Android API 26+
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

- **`CryptoService`** — keypair generation, signing, verification, encryption, decryption, key exchange, feed key management, hashing
- **`StorageService`** — event CRUD, follow CRUD, media cache, identity, outbound queue, retention
- **`TorService`** — onion service lifecycle, outbound Tor connections, .onion address persistence, status
- **`NetworkService`** — peer discovery, connection resolution (LAN/relay/Tor), HTTP client for peer endpoints

### Mock implementations
In-memory mock for each service interface. Used for testing and initial UI development before native FFI is wired up.

### Models
Dart data classes with CBOR serialization:
- `Event` — version, id, pubkey, created_at, kind, ref, content, media, sig
- `EncryptedEvent` — pubkey, created_at, nonce, payload
- `MediaRef` — hash, mime_type, size
- `ConnectionCard` — pubkey, endpoints list
- Event kind enum: post(1), profile(2), followList(3), comment(4), like(5), delete(6)

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
- `mobile_scanner`, `qr_flutter`
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
- `lib/services/crypto_service.dart`
- `lib/services/storage_service.dart`
- `lib/services/tor_service.dart`
- `lib/services/network_service.dart`
- `lib/services/mocks/mock_crypto_service.dart`
- `lib/services/mocks/mock_storage_service.dart`
- `lib/services/mocks/mock_tor_service.dart`
- `lib/services/mocks/mock_network_service.dart`
- `lib/models/event.dart`
- `lib/models/encrypted_event.dart`
- `lib/models/media_ref.dart`
- `lib/models/connection_card.dart`
- `lib/models/event_kind.dart`
- `lib/providers/service_providers.dart`
- `lib/main.dart`
- `test/models/event_serialization_test.dart`

## Verification
- `flutter analyze` — zero issues
- `flutter test` — passes (model serialization round-trips)
- App builds and launches on iOS simulator and Android emulator
- Mock services injectable and swappable via Riverpod overrides
- Event model round-trips through CBOR: create → serialize → deserialize → fields match

## Key decisions
- Package name `dev.finch.app` — affects keychain access group, deep link scheme, mDNS service name
- iOS 17+ / Android API 26+ — modern crypto and keychain APIs
- All service interfaces are abstract classes, not mixins or extension types

## Risks
- Getting the abstract interfaces right is critical. Under-specifying them means refactoring every downstream plan. Spend time here — read the protocol spec and app spec carefully before finalizing method signatures.
- Riverpod code generation adds a build step. Establish the `build_runner` workflow early so it doesn't slow down later plans.
