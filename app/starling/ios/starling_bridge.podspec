Pod::Spec.new do |s|
  s.name             = 'starling_bridge'
  s.version          = '0.1.0'
  s.summary          = 'Starling native FFI bridge — Tor (arti) + libp2p direct, merged.'
  s.description      = <<~DESC
    Single Rust staticlib + xcframework exporting both the arti_* (Tor
    onion service / SOCKS) and lp_* (libp2p direct-connect QUIC) FFI
    surfaces used by the Flutter app. Replaces the old separate
    `arti_bridge` and `libp2p_bridge` pods — the split caused ~584
    duplicate-symbol link errors because each staticlib bundled its
    own copy of `ring` + `compiler_builtins`. Merging them gives the
    iOS linker exactly one copy of every shared dependency.
  DESC
  s.homepage         = 'https://github.com/starling-app/starling'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Starling' => 'team@starling.app' }
  s.source           = { :path => '.' }

  # Tracks the Flutter app's deployment target (ios/Podfile + Runner
  # xcodeproj IPHONEOS_DEPLOYMENT_TARGET). Also pinned in
  # native/starling_bridge/build.sh as IPHONEOS_DEPLOYMENT_TARGET.
  s.platform         = :ios, '26.0'

  # Produced by `native/starling_bridge/build.sh ios`. If pod install
  # fails because this file is missing, run
  # `(cd native/starling_bridge && ./build.sh ios)`.
  s.vendored_frameworks = 'Runner/starling_bridge.xcframework'

  # The Rust crate produces a system static library — surface what its
  # transitive C symbols need:
  #   - c++         : Rust's panic-unwind runtime + a couple of C++ symbols
  #                   pulled in transitively
  #   - sqlite3     : tor_dirmgr → rusqlite → libsqlite3-sys. On Android we
  #                   bundle sqlite (Cargo `bundled` feature); on iOS we
  #                   link the system libsqlite3 here.
  #   - Security    : both arti and libp2p use Apple's Security framework
  #                   transitively (rustls system trust, keychain access)
  #   - SystemConfiguration : `if-watch` crate's `SCDynamicStore*` calls
  #                   for IPv6 interface enumeration (Plan 11c)
  s.requires_arc      = true
  s.libraries         = 'c++', 'sqlite3'
  s.frameworks        = 'Security', 'SystemConfiguration'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'         => 'YES',
    'CLANG_ENABLE_MODULES'   => 'YES',
  }

  # The `-force_load` flag is injected by `Podfile`'s post_install hook
  # directly on the Runner xcodeproj. Setting it here would require
  # `user_target_xcconfig` which CocoaPods treats with singular-merge
  # semantics for per-SDK conditional keys — fine when there's only one
  # pod doing it, but the pattern is preserved from the pre-merge state
  # so that any future second native pod can co-exist.
end
