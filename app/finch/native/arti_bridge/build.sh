#!/usr/bin/env bash
# Cross-compile arti_bridge for iOS and Android, packaging results into
# the spots `Runner.xcodeproj` and the Android Gradle build expect.
#
# Usage:
#   ./build.sh           # all targets (iOS + Android)
#   ./build.sh ios       # iOS only
#   ./build.sh android   # Android only
#   ./build.sh host      # host target (for `cargo check` parity)
#
# Prerequisites: see README.md — rustup targets, cargo-ndk, ANDROID_NDK_HOME.

set -euo pipefail

CRATE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$CRATE_DIR/../.." && pwd)"
TARGET_DIR="$CRATE_DIR/target"

IOS_FRAMEWORK_OUT="$APP_DIR/ios/Runner/arti_bridge.xcframework"
ANDROID_JNILIBS_OUT="$APP_DIR/android/app/src/main/jniLibs"
HEADER_DIR="$CRATE_DIR/include"

CARGO="${CARGO:-cargo}"
RUST_TARGETS_IOS=(
  aarch64-apple-ios          # device arm64
  aarch64-apple-ios-sim      # Apple-silicon simulator
  x86_64-apple-ios           # Intel-Mac simulator
)
RUST_TARGETS_ANDROID=(
  aarch64-linux-android
  x86_64-linux-android
)

PROFILE="release"

cmd="${1:-all}"

build_host() {
  echo "==> host: cargo build --release"
  (cd "$CRATE_DIR" && "$CARGO" build --release)
}

build_ios() {
  echo "==> iOS targets:"
  for t in "${RUST_TARGETS_IOS[@]}"; do
    echo "    - $t"
    (cd "$CRATE_DIR" && "$CARGO" build --release --target "$t")
  done

  # Combine simulator slices into a single fat static library so the
  # xcframework only has two slices (device + simulator). xcodebuild
  # -create-xcframework refuses overlapping slices.
  local sim_dir="$TARGET_DIR/sim-fat"
  mkdir -p "$sim_dir"
  lipo -create \
    "$TARGET_DIR/aarch64-apple-ios-sim/$PROFILE/libarti_bridge.a" \
    "$TARGET_DIR/x86_64-apple-ios/$PROFILE/libarti_bridge.a" \
    -output "$sim_dir/libarti_bridge.a"

  rm -rf "$IOS_FRAMEWORK_OUT"
  xcodebuild -create-xcframework \
    -library "$TARGET_DIR/aarch64-apple-ios/$PROFILE/libarti_bridge.a" \
      -headers "$HEADER_DIR" \
    -library "$sim_dir/libarti_bridge.a" \
      -headers "$HEADER_DIR" \
    -output "$IOS_FRAMEWORK_OUT"
  echo "    wrote $IOS_FRAMEWORK_OUT"
}

build_android() {
  if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    echo "ERROR: ANDROID_NDK_HOME must be set for Android builds." >&2
    exit 1
  fi
  if ! command -v cargo-ndk >/dev/null; then
    echo "ERROR: cargo-ndk not installed (cargo install cargo-ndk)." >&2
    exit 1
  fi

  echo "==> Android targets via cargo-ndk:"
  local args=()
  for t in "${RUST_TARGETS_ANDROID[@]}"; do
    args+=(-t "$t")
  done

  rm -rf "$ANDROID_JNILIBS_OUT"
  (cd "$CRATE_DIR" && cargo ndk "${args[@]}" \
    -o "$ANDROID_JNILIBS_OUT" \
    build --release)
  echo "    wrote $ANDROID_JNILIBS_OUT"
}

case "$cmd" in
  all)
    build_ios
    build_android
    ;;
  ios)     build_ios ;;
  android) build_android ;;
  host)    build_host ;;
  *)
    echo "unknown subcommand: $cmd" >&2
    echo "usage: $0 [all|ios|android|host]" >&2
    exit 2
    ;;
esac

echo "==> done"
