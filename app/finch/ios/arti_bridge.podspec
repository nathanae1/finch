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
  s.requires_arc      = true
  s.libraries         = 'c++'
  s.frameworks        = 'Security'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'         => 'YES',
    'CLANG_ENABLE_MODULES'   => 'YES',
  }
end
