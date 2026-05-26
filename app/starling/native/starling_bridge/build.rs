use std::env;
use std::path::PathBuf;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let out_dir = PathBuf::from(&crate_dir).join("include");
    std::fs::create_dir_all(&out_dir).ok();
    let header_path = out_dir.join("starling_bridge.h");

    match cbindgen::generate(&crate_dir) {
        Ok(bindings) => {
            bindings.write_to_file(&header_path);
        }
        Err(e) => {
            // Don't fail the build if cbindgen can't run (e.g. inside docs.rs);
            // the header is only needed for FFI consumers that pull from /include.
            println!("cargo:warning=cbindgen failed: {e}");
        }
    }

    println!("cargo:rerun-if-changed=src/lib.rs");
    println!("cargo:rerun-if-changed=src/arti/mod.rs");
    println!("cargo:rerun-if-changed=src/arti/inner.rs");
    println!("cargo:rerun-if-changed=src/p2p/mod.rs");
    println!("cargo:rerun-if-changed=src/p2p/inner.rs");
    println!("cargo:rerun-if-changed=src/p2p/interfaces.rs");
    println!("cargo:rerun-if-changed=cbindgen.toml");
}
