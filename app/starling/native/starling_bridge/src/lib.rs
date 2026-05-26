// Merged FFI crate: arti_bridge (Tor) + libp2p_bridge (direct-connect)
// in one staticlib. See Cargo.toml for the rationale; the short version
// is that two independent Rust staticlibs both pulling in `ring` and
// `compiler_builtins` produced ~584 duplicate strong symbols at iOS
// link time, and Apple's ld-prime no longer tolerates `-multiply_defined
// suppress`. Merging the crates gives the linker exactly one copy of
// every shared dependency.
//
// `#[no_mangle] pub extern "C" fn` in nested modules exports at the
// staticlib level regardless of the Rust module path, so we do not need
// to re-export the FFI surface at this level.

#![allow(clippy::missing_safety_doc)]

pub mod arti;
pub mod p2p;
