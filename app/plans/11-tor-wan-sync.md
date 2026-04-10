# Plan 11: Tor & WAN Sync (Arti FFI)

## Dependencies
Plan 07 (HTTP server — Tor points to it), Plan 09 (sync engine — Tor is a new tier)

## Scope

Embed the Arti Tor client via FFI. Create onion services. Enable sync between devices not on the same network. **This is the highest technical risk in the entire project.**

### Arti integration

**Rust bridge crate** (`native/arti_bridge/`):
- Rust crate wrapping Arti with a C-compatible API
- Functions exposed via `#[no_mangle] extern "C"`:
  - `arti_init(data_dir) → handle` — initialize Tor client, bootstrap circuits
  - `arti_create_onion_service(handle, local_port) → onion_address` — create hidden service pointing to local HTTP server
  - `arti_connect(handle, onion_address, port) → connection` — outbound connection to a .onion
  - `arti_status(handle) → status` — bootstrap progress, circuit count
  - `arti_shutdown(handle)` — graceful shutdown
- `cbindgen` generates C headers from Rust
- Cross-compilation targets: iOS arm64, Android arm64 + x86_64

**Build pipeline:**
- Rust source in `native/arti_bridge/`
- Build script produces:
  - iOS: `arti_bridge.xcframework` (static library)
  - Android: `libarti_bridge.so` per architecture in `jniLibs/`
- Prebuilt binaries checked into repo (or CI-built)
- Dart FFI bindings in `lib/services/tor/ffi_bindings.dart`

### TorService implementation
Implement the abstract `TorService` interface:
- **init()** — load Arti, bootstrap (10-30s). App must be usable during bootstrap (LAN sync works immediately).
- **createOnionService(localPort)** — start hidden service, return .onion address
- **connectToOnion(address)** — return a connection/stream usable for HTTP requests
- **getStatus()** — bootstrap %, circuit count, is_ready
- **shutdown()** — clean teardown
- Persist `.onion` address across app restarts (Arti keypair stored in data dir)

### Connection card update
- After onion service is created, update connection card to include onion endpoint
- `{ pubkey, endpoints: [{ type: "onion", address: "abc...xyz.onion" }] }`
- Followers who have your connection card can now reach you via Tor

### Sync engine update
- Add Tor as connection tier: LAN → relay → Tor (relay added in Plan 15)
- When syncing with a followed account:
  1. Check mDNS cache (LAN)
  2. If not on LAN, check connection card for onion endpoint
  3. Connect via Tor, perform same manifest exchange + event pull
- Tor connections are slower (3-5s per request). Acceptable for async feed.

### Follow handshake over Tor
- Follow requests and accepts can now traverse the internet via Tor
- No longer requires both parties to be on the same WiFi

### Tor lifecycle
- **iOS**: start on app foreground, stop on background (OS kills background processes)
- **Android**: start on app foreground. Optional foreground service for persistence (Plan 14)
- Bootstrap status shown in UI during startup

### Settings UI
- Tor status widget: "Connecting..." / "Connected (3 circuits)" / "Offline"
- .onion address display (copyable)
- Tor on/off toggle (opt-out for users who only want LAN)

## Files created/modified
- `native/arti_bridge/Cargo.toml`
- `native/arti_bridge/src/lib.rs` — C API wrapper around Arti
- `native/arti_bridge/cbindgen.toml`
- `native/arti_bridge/build.sh` — cross-compilation script
- `ios/Runner/arti_bridge.xcframework` (prebuilt)
- `android/app/src/main/jniLibs/{arch}/libarti_bridge.so` (prebuilt)
- `lib/services/tor/arti_tor_service.dart` — TorService implementation
- `lib/services/tor/ffi_bindings.dart` — Dart FFI bindings
- `lib/providers/tor_provider.dart`
- `lib/screens/settings/tor_status_widget.dart`
- `lib/sync/sync_engine.dart` (update: add Tor tier)
- `lib/sync/peer_connection.dart` (update: Tor-based connections)
- `lib/providers/identity_provider.dart` (update: connection card with onion)
- `test/services/tor/` — integration tests (require network access)

## Verification
- Arti initializes successfully on iOS and Android real devices
- Bootstrap completes within 30s on reasonable network
- Onion service is created: .onion address logged
- .onion address persists across app restarts
- Connection card includes onion endpoint
- **Two devices NOT on the same WiFi can sync**: Device A on WiFi, Device B on cellular → B pull-to-refresh → A's posts appear
- Follow request sent over Tor succeeds
- Follow accept received over Tor succeeds
- Tor status displays correctly in Settings
- App handles Tor failure gracefully: falls back to LAN-only, shows status
- App is usable during Tor bootstrap (LAN sync works immediately)

## Key decisions
- Prebuilt binaries vs CI-built: recommend prebuilt checked into repo for MVP. CI can be added later.
- Arti data directory: `{app_dir}/tor/` — stores Tor state, circuit cache, onion service keypair
- Tor bootstrap timeout: 60s. After that, log warning and continue without Tor.
- Outbound Tor connections: Arti's SOCKS5 proxy interface is the most stable path. Connect to SOCKS proxy, then HTTP through it.

## Risks
- **This is the single highest-risk plan.** Arti's onion service API may be immature or unstable on mobile. Spike this early — do a proof-of-concept during Plan 01 or 02 to validate that Arti can:
  1. Bootstrap on iOS and Android
  2. Create an onion service
  3. Accept incoming connections to that service
  If this spike fails, the fallback is: LAN-only for Phase 1, relay (Plan 15) as the only WAN path.
- Cross-compilation for iOS (arm64, static framework) and Android (arm64, x86_64, shared library) is non-trivial. Budget significant time for the build pipeline.
- Binary size: Arti may add 10-20MB to the app. Measure and accept or strip unused features.
- Tor bootstrap takes 10-30s. During this time, only LAN sync works. The UX must not block on Tor.
- iOS background restrictions: onion service dies immediately when backgrounded. This is fundamental to iOS and cannot be worked around.
