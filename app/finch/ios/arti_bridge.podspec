Pod::Spec.new do |s|
  s.name             = 'arti_bridge'
  s.version          = '0.1.0'
  s.summary          = 'Finch Arti/Tor FFI bridge (Plan 11).'
  s.description      = 'Vendored static xcframework wrapping arti-client + tor-hsservice for Finch.'
  s.homepage         = 'https://github.com/finch-app/finch'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Finch' => 'team@finch.app' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '17.0'

  # The xcframework is produced by `native/arti_bridge/build.sh ios` and
  # checked into the repo at the path below. If pod install fails because
  # this file is missing, run `(cd native/arti_bridge && ./build.sh ios)`.
  s.vendored_frameworks = 'Runner/arti_bridge.xcframework'

  # The Rust crate produces a system static library — surface it so the
  # linker resolves the C symbols used by lib/services/tor/ffi_bindings.dart.
  # `sqlite3` is iOS-system libsqlite3 — Arti's tor_dirmgr uses rusqlite for
  # its directory cache, which dyld previously got via sqlcipher_flutter_libs
  # (SQLCipher exports the same C ABI). We retired that pod, so link the
  # system sqlite3 directly.
  s.requires_arc      = true
  s.libraries         = 'c++', 'sqlite3'
  s.frameworks        = 'Security'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'         => 'YES',
    'CLANG_ENABLE_MODULES'   => 'YES',
  }

  # The Dart side resolves `arti_init` etc. via runtime `dlsym`, which is
  # invisible to the static linker. Without `-force_load` here the linker
  # dead-strips every symbol in `libarti_bridge.a` (no Swift/ObjC code
  # references them), and Dart bindings fail at startup with
  # "symbol not found: arti_init". Force-load the whole archive so every
  # exported C symbol stays in the final binary's dynamic symbol table.
  #
  # We reference the source xcframework directly (rather than the
  # CocoaPods-copied path under PODS_XCFRAMEWORKS_BUILD_DIR) because the
  # generated xcfilelist for static-library xcframeworks claims its
  # output is `arti_bridge.framework` rather than `libarti_bridge.a`,
  # which trips Xcode's input-existence check at link planning time.
  # The source path here is always present (checked into the repo,
  # rebuilt by `native/arti_bridge/build.sh ios`) so there's no
  # ordering dependency on the xcframework copy script.
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS[sdk=iphoneos*]'        => '$(inherited) -force_load "$(SRCROOT)/Runner/arti_bridge.xcframework/ios-arm64/libarti_bridge.a"',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -force_load "$(SRCROOT)/Runner/arti_bridge.xcframework/ios-arm64_x86_64-simulator/libarti_bridge.a"',
  }
end
