//! p2p — libp2p direct-connect FFI surface (QUIC + Noise + yamux +
//! Identify) for Starling's mobile app.
//!
//! Plan 11a — direct-connect transport tier. Sibling of `arti`, same
//! FFI patterns:
//! - One opaque [`LpHandle`] owns a tokio runtime + a [`Swarm`] + state.
//! - Every FFI call is wrapped in `catch_unwind` so we never unwind into
//!   Dart. Returned status codes are negative on error.
//! - Swarm events are delivered to Dart via the registered Native Port
//!   using `Dart_PostCObject` so the FFI call site never blocks on
//!   event delivery.
//!
//! Lives at `crate::p2p` in the merged starling_bridge crate. The
//! submodule is named `p2p` rather than `libp2p` so the `libp2p` *crate*
//! stays unambiguously addressable inside this module's source files.

#![allow(clippy::missing_safety_doc)]

use std::cell::RefCell;
use std::ffi::{c_char, c_int, CStr};
use std::os::raw::c_void;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;
use std::sync::atomic::Ordering;
use std::sync::Arc;
use std::time::Duration;

use libp2p::{Multiaddr, StreamProtocol};
use parking_lot::Mutex;
use tokio::sync::oneshot;
use zeroize::Zeroize;

pub(crate) mod inner;
pub(crate) mod interfaces;

use inner::{Cmd, Inner, ReadEvent, WriteCmd};

thread_local! {
    /// Most recent error message produced by an FFI call on this thread.
    /// Populated whenever an FFI returns NULL or a negative status; the
    /// caller can retrieve it via [`lp_last_error`] for richer diagnostics
    /// than the bare integer status code allows.
    static LAST_ERROR: RefCell<Option<String>> = const { RefCell::new(None) };
}

/// Process-wide handle slot. Survives Flutter hot restart (which destroys
/// the Dart isolate but leaves the native process alive). Tracks the
/// most recent live handle so a subsequent `lp_init` can tear the orphan
/// down before building a fresh one. Cleared by [`lp_shutdown`].
static HANDLE_SLOT: Mutex<Option<usize>> = Mutex::new(None);

fn set_last_error(msg: impl Into<String>) {
    LAST_ERROR.with(|slot| *slot.borrow_mut() = Some(msg.into()));
}

fn clear_last_error() {
    LAST_ERROR.with(|slot| *slot.borrow_mut() = None);
}

// --- Status codes ---
// Layout MUST match `Libp2pStatusCode` in `lib/services/libp2p/ffi_bindings.dart`.

pub const LP_OK: c_int = 0;
pub const LP_ERR_NULL: c_int = -1;
pub const LP_ERR_UTF8: c_int = -2;
pub const LP_ERR_PANIC: c_int = -3;
pub const LP_ERR_NOT_INITIALIZED: c_int = -4;
pub const LP_ERR_LISTEN: c_int = -5;
pub const LP_ERR_DIAL_TIMEOUT: c_int = -6;
pub const LP_ERR_PROTOCOL: c_int = -7;
pub const LP_ERR_STREAM_CLOSED: c_int = -8;
pub const LP_ERR_BUFFER_TOO_SMALL: c_int = -9;
pub const LP_ERR_UNIMPLEMENTED: c_int = -10;

/// Opaque handle returned by [`lp_init`].
pub struct LpHandle {
    inner: Arc<Inner>,
}

// --- FFI surface ---

/// Initialize the libp2p bridge and return an opaque handle.
///
/// - `data_dir`: filesystem path for libp2p PeerStore caches (no secrets).
/// - `seed_ptr`/`seed_len`: 32-byte Ed25519 seed. The bridge copies the
///   seed into Rust, constructs the keypair, and zeroizes its copy. The
///   caller MUST zeroize its buffer immediately on return.
/// - `post_c_object_fn_ptr`: pointer obtained from
///   `NativeApi.postCObject` on the Dart side. Stored process-globally via
///   `allo-isolate` so the event loop can `Dart_PostCObject(port, msg)`
///   from non-isolate tokio threads. Pass NULL to disable event delivery
///   (tests that don't care about Swarm events).
///
/// Returns NULL on failure with [`lp_last_error`] populated.
#[no_mangle]
pub unsafe extern "C" fn lp_init(
    data_dir: *const c_char,
    seed_ptr: *const u8,
    seed_len: usize,
    post_c_object_fn_ptr: *mut c_void,
) -> *mut LpHandle {
    clear_last_error();
    let res = catch_unwind(AssertUnwindSafe(|| -> Result<*mut LpHandle, String> {
        if data_dir.is_null() || seed_ptr.is_null() {
            return Err("data_dir or seed pointer was null".into());
        }
        if seed_len != 32 {
            return Err(format!("expected 32-byte Ed25519 seed, got {seed_len}"));
        }
        let _data_dir = CStr::from_ptr(data_dir)
            .to_str()
            .map_err(|e| format!("data_dir not UTF-8: {e}"))?;

        // Copy the seed into a stack array and zeroize when we're done.
        let mut seed = [0u8; 32];
        seed.copy_from_slice(std::slice::from_raw_parts(seed_ptr, 32));
        let inner = Inner::new(&seed).map_err(|e| format!("inner: {e:#}"))?;
        seed.zeroize();

        if !post_c_object_fn_ptr.is_null() {
            let f: allo_isolate::ffi::DartPostCObjectFnType =
                std::mem::transmute(post_c_object_fn_ptr);
            allo_isolate::store_dart_post_cobject(f);
        }

        let handle = Box::new(LpHandle { inner });
        let raw = Box::into_raw(handle);
        *HANDLE_SLOT.lock() = Some(raw as usize);
        Ok(raw)
    }));
    match res {
        Ok(Ok(handle)) => handle,
        Ok(Err(msg)) => {
            set_last_error(msg);
            ptr::null_mut()
        }
        Err(_) => {
            set_last_error("panic in lp_init");
            ptr::null_mut()
        }
    }
}

/// Bind UDP/QUIC listeners on `/ip4/0.0.0.0/udp/0/quic-v1` and start the
/// swarm event loop. Idempotent.
#[no_mangle]
pub unsafe extern "C" fn lp_listen(handle: *mut LpHandle) -> c_int {
    guard_handle(handle, |h| match h.inner.start_listen() {
        Ok(()) => LP_OK,
        Err(e) => {
            set_last_error(format!("listen: {e:#}"));
            LP_ERR_LISTEN
        }
    })
}

/// Write a CBOR-encoded list of currently-observed external multiaddrs
/// into `out_buf`. Returns the number of bytes written or
/// [`LP_ERR_BUFFER_TOO_SMALL`].
#[no_mangle]
pub unsafe extern "C" fn lp_observed_addrs(
    handle: *mut LpHandle,
    out_buf: *mut u8,
    buf_len: usize,
) -> isize {
    if handle.is_null() {
        set_last_error("null handle");
        return LP_ERR_NULL as isize;
    }
    let h = &*handle;
    let res = catch_unwind(AssertUnwindSafe(|| -> isize {
        let addrs = h.inner.observed_addrs.read();
        let bytes = inner::encode_observed_addrs_cbor(&addrs);
        if bytes.len() > buf_len {
            return LP_ERR_BUFFER_TOO_SMALL as isize;
        }
        if !out_buf.is_null() {
            std::ptr::copy_nonoverlapping(bytes.as_ptr(), out_buf, bytes.len());
        }
        bytes.len() as isize
    }));
    res.unwrap_or_else(|_| {
        set_last_error("panic in lp_observed_addrs");
        LP_ERR_PANIC as isize
    })
}

/// Inject an externally observed multiaddr.
#[no_mangle]
pub unsafe extern "C" fn lp_add_observed_addr(
    handle: *mut LpHandle,
    multiaddr_ptr: *const u8,
    len: usize,
) -> c_int {
    guard_handle(handle, |h| {
        if multiaddr_ptr.is_null() {
            return LP_ERR_NULL;
        }
        let bytes = std::slice::from_raw_parts(multiaddr_ptr, len).to_vec();
        let addr = match Multiaddr::try_from(bytes) {
            Ok(a) => a,
            Err(e) => {
                set_last_error(format!("bad multiaddr: {e}"));
                return LP_ERR_PROTOCOL;
            }
        };
        let result = h.inner.block_on_cmd(
            |reply| Cmd::AddObservedAddr { addr, reply },
            Duration::from_secs(2),
        );
        match result {
            Ok(Ok(())) => LP_OK,
            Ok(Err(e)) | Err(e) => {
                set_last_error(e);
                LP_ERR_PROTOCOL
            }
        }
    })
}

/// Issue a DCUtR-aware direct dial. Returns a positive connection id or
/// a negative [`LP_ERR_*`].
#[no_mangle]
pub unsafe extern "C" fn lp_dial_direct(
    handle: *mut LpHandle,
    peer_id_cstr: *const c_char,
    addrs_cbor: *const u8,
    addrs_len: usize,
    timeout_ms: u32,
) -> i64 {
    guard_handle_i64(handle, |h| {
        if peer_id_cstr.is_null() || addrs_cbor.is_null() {
            return LP_ERR_NULL as i64;
        }
        let peer_str = match CStr::from_ptr(peer_id_cstr).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_last_error("peer_id not UTF-8");
                return LP_ERR_UTF8 as i64;
            }
        };
        let peer = match inner::parse_peer_id(peer_str) {
            Ok(p) => p,
            Err(e) => {
                set_last_error(e);
                return LP_ERR_PROTOCOL as i64;
            }
        };
        let addrs_bytes = std::slice::from_raw_parts(addrs_cbor, addrs_len);
        let addrs = match inner::decode_addrs_cbor(addrs_bytes) {
            Ok(a) => a,
            Err(e) => {
                set_last_error(e);
                return LP_ERR_PROTOCOL as i64;
            }
        };
        let timeout = Duration::from_millis(timeout_ms.into());
        let inner_arc = Arc::clone(&h.inner);
        let result = h
            .inner
            .runtime
            .block_on(async move { inner_arc.dial_direct(peer, addrs, timeout).await });
        match result {
            Ok(id) => id,
            Err(e) => {
                set_last_error(e);
                LP_ERR_DIAL_TIMEOUT as i64
            }
        }
    })
}

/// Open a libp2p stream for `protocol_cstr` over an existing connection.
/// Returns a positive stream id or a negative [`LP_ERR_*`].
#[no_mangle]
pub unsafe extern "C" fn lp_open_stream(
    handle: *mut LpHandle,
    conn_id: i64,
    protocol_cstr: *const c_char,
) -> i64 {
    guard_handle_i64(handle, |h| {
        if protocol_cstr.is_null() {
            return LP_ERR_NULL as i64;
        }
        let protocol = match CStr::from_ptr(protocol_cstr).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => {
                set_last_error("protocol not UTF-8");
                return LP_ERR_UTF8 as i64;
            }
        };
        let inner_arc = Arc::clone(&h.inner);
        let result = h
            .inner
            .runtime
            .block_on(async move { inner_arc.open_outbound_stream(conn_id, protocol).await });
        match result {
            Ok(id) => id,
            Err(e) => {
                set_last_error(e);
                LP_ERR_PROTOCOL as i64
            }
        }
    })
}

/// Write one length-delimited frame to a stream.
#[no_mangle]
pub unsafe extern "C" fn lp_stream_write(
    handle: *mut LpHandle,
    stream_id: i64,
    data_ptr: *const u8,
    len: usize,
    finish: bool,
) -> c_int {
    guard_handle(handle, |h| {
        if data_ptr.is_null() && len != 0 {
            return LP_ERR_NULL;
        }
        let data = std::slice::from_raw_parts(data_ptr, len).to_vec();
        let stream = match h.inner.streams.read().get(&stream_id).cloned() {
            Some(s) => s,
            None => {
                set_last_error("unknown stream id");
                return LP_ERR_STREAM_CLOSED;
            }
        };
        let (tx, rx) = oneshot::channel();
        if stream
            .write_tx
            .send(WriteCmd::Frame {
                data,
                finish,
                reply: tx,
            })
            .is_err()
        {
            set_last_error("stream writer task gone");
            return LP_ERR_STREAM_CLOSED;
        }
        let result = h
            .inner
            .runtime
            .block_on(async move { tokio::time::timeout(Duration::from_secs(30), rx).await });
        match result {
            Ok(Ok(Ok(()))) => LP_OK,
            Ok(Ok(Err(e))) => {
                set_last_error(e);
                LP_ERR_STREAM_CLOSED
            }
            Ok(Err(_)) => {
                set_last_error("write reply dropped");
                LP_ERR_STREAM_CLOSED
            }
            Err(_) => {
                set_last_error("write timeout");
                LP_ERR_DIAL_TIMEOUT
            }
        }
    })
}

/// Read exactly one length-delimited frame. Returns bytes written into
/// `out_buf`, or a negative [`LP_ERR_*`].
#[no_mangle]
pub unsafe extern "C" fn lp_stream_read(
    handle: *mut LpHandle,
    stream_id: i64,
    out_buf: *mut u8,
    buf_len: usize,
    timeout_ms: u32,
) -> isize {
    if handle.is_null() {
        set_last_error("null handle");
        return LP_ERR_NULL as isize;
    }
    let h = &*handle;
    let res = catch_unwind(AssertUnwindSafe(|| -> isize {
        let stream = match h.inner.streams.read().get(&stream_id).cloned() {
            Some(s) => s,
            None => {
                set_last_error("unknown stream id");
                return LP_ERR_STREAM_CLOSED as isize;
            }
        };

        // Plan 11c — if a previous call returned ERR_BUFFER_TOO_SMALL,
        // the frame was stashed here. Try to satisfy the read from the
        // stash before pulling from the receiver, so a doubling-buffer
        // retry on the Dart side genuinely gets the same frame back.
        if let Some(bytes) = stream.pending_frame.lock().take() {
            if bytes.len() > buf_len {
                set_last_error(format!(
                    "frame too large for buffer ({} > {})",
                    bytes.len(),
                    buf_len
                ));
                // Put it back; caller will retry with a bigger buffer.
                *stream.pending_frame.lock() = Some(bytes);
                return LP_ERR_BUFFER_TOO_SMALL as isize;
            }
            std::ptr::copy_nonoverlapping(bytes.as_ptr(), out_buf, bytes.len());
            return bytes.len() as isize;
        }

        let timeout = Duration::from_millis(timeout_ms.into());
        let result = h.inner.runtime.block_on(async {
            let mut rx_guard = stream.read_rx.lock().await;
            tokio::time::timeout(timeout, rx_guard.recv()).await
        });
        match result {
            Ok(Some(ReadEvent::Frame(bytes))) => {
                if bytes.len() > buf_len {
                    // Plan 11c — stash the frame so the caller can retry
                    // with a bigger buffer (Dart-side `_FfiStream.read`
                    // doubles its buffer up to 16 MiB). Previously we
                    // dropped the frame here, losing every message
                    // larger than the caller's initial buffer.
                    set_last_error(format!(
                        "frame too large for buffer ({} > {})",
                        bytes.len(),
                        buf_len
                    ));
                    *stream.pending_frame.lock() = Some(bytes);
                    LP_ERR_BUFFER_TOO_SMALL as isize
                } else {
                    std::ptr::copy_nonoverlapping(bytes.as_ptr(), out_buf, bytes.len());
                    bytes.len() as isize
                }
            }
            Ok(Some(ReadEvent::Closed)) | Ok(None) => {
                set_last_error("stream closed");
                LP_ERR_STREAM_CLOSED as isize
            }
            Ok(Some(ReadEvent::Error(e))) => {
                set_last_error(e);
                LP_ERR_STREAM_CLOSED as isize
            }
            Err(_) => {
                set_last_error("read timeout");
                LP_ERR_DIAL_TIMEOUT as isize
            }
        }
    }));
    res.unwrap_or_else(|_| {
        set_last_error("panic in lp_stream_read");
        LP_ERR_PANIC as isize
    })
}

/// Close a stream.
#[no_mangle]
pub unsafe extern "C" fn lp_stream_close(handle: *mut LpHandle, stream_id: i64) -> c_int {
    guard_handle(handle, |h| {
        let stream = match h.inner.streams.read().get(&stream_id).cloned() {
            Some(s) => s,
            None => {
                // Already gone — treat as success.
                return LP_OK;
            }
        };
        let (tx, rx) = oneshot::channel();
        let _ = stream.write_tx.send(WriteCmd::Close(tx));
        let _ = h
            .inner
            .runtime
            .block_on(async { tokio::time::timeout(Duration::from_secs(2), rx).await });
        h.inner.drop_stream(stream_id);
        LP_OK
    })
}

/// Register a Dart Native Port for event delivery.
#[no_mangle]
pub unsafe extern "C" fn lp_set_event_port(handle: *mut LpHandle, native_port: i64) -> c_int {
    guard_handle(handle, |h| {
        h.inner.event_port.store(native_port, Ordering::Release);
        LP_OK
    })
}

/// Register an inbound stream handler for `protocol_cstr`.
#[no_mangle]
pub unsafe extern "C" fn lp_register_inbound_handler(
    handle: *mut LpHandle,
    protocol_cstr: *const c_char,
) -> c_int {
    guard_handle(handle, |h| {
        if protocol_cstr.is_null() {
            return LP_ERR_NULL;
        }
        let s = match CStr::from_ptr(protocol_cstr).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => return LP_ERR_UTF8,
        };
        let protocol = match StreamProtocol::try_from_owned(s.clone()) {
            Ok(p) => p,
            Err(e) => {
                set_last_error(format!("bad protocol: {e}"));
                return LP_ERR_PROTOCOL;
            }
        };
        let result = h.inner.block_on_cmd(
            |reply| Cmd::RegisterInbound { protocol, reply },
            Duration::from_secs(2),
        );
        match result {
            Ok(Ok(())) => LP_OK,
            Ok(Err(e)) | Err(e) => {
                set_last_error(e);
                LP_ERR_PROTOCOL
            }
        }
    })
}

/// Returns the local base58-encoded PeerId. Caller frees with
/// [`lp_string_free`]. Returns NULL before [`lp_init`].
#[no_mangle]
pub unsafe extern "C" fn lp_local_peer_id(handle: *mut LpHandle) -> *mut c_char {
    if handle.is_null() {
        set_last_error("lp_local_peer_id called with null handle");
        return ptr::null_mut();
    }
    let h = &*handle;
    let res = catch_unwind(AssertUnwindSafe(|| -> *mut c_char {
        let s = h.inner.local_peer_id.to_base58();
        match std::ffi::CString::new(s) {
            Ok(c) => c.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }));
    res.unwrap_or_else(|_| {
        set_last_error("panic in lp_local_peer_id");
        ptr::null_mut()
    })
}

/// Stop the swarm event loop and close all listeners.
#[no_mangle]
pub unsafe extern "C" fn lp_shutdown(handle: *mut LpHandle) -> c_int {
    if handle.is_null() {
        return LP_ERR_NULL;
    }
    let res = catch_unwind(AssertUnwindSafe(|| {
        let lp = Box::from_raw(handle);
        lp.inner.shutdown();
        *HANDLE_SLOT.lock() = None;
        LP_OK
    }));
    res.unwrap_or(LP_ERR_PANIC)
}

/// Most recent error message on this thread. Caller frees with
/// [`lp_string_free`].
#[no_mangle]
pub unsafe extern "C" fn lp_last_error() -> *mut c_char {
    let msg = LAST_ERROR.with(|slot| slot.borrow().clone());
    match msg {
        Some(s) => match std::ffi::CString::new(s) {
            Ok(c) => c.into_raw(),
            Err(_) => ptr::null_mut(),
        },
        None => ptr::null_mut(),
    }
}

/// Free a string returned by the bridge.
#[no_mangle]
pub unsafe extern "C" fn lp_string_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = std::ffi::CString::from_raw(ptr);
    }
}

// --- helpers ---

fn guard_handle<F>(handle: *mut LpHandle, f: F) -> c_int
where
    F: FnOnce(&LpHandle) -> c_int,
{
    if handle.is_null() {
        set_last_error("null handle");
        return LP_ERR_NULL;
    }
    let res = catch_unwind(AssertUnwindSafe(|| {
        let h = unsafe { &*handle };
        f(h)
    }));
    match res {
        Ok(code) => code,
        Err(_) => {
            set_last_error("panic at FFI boundary");
            LP_ERR_PANIC
        }
    }
}

fn guard_handle_i64<F>(handle: *mut LpHandle, f: F) -> i64
where
    F: FnOnce(&LpHandle) -> i64,
{
    if handle.is_null() {
        set_last_error("null handle");
        return LP_ERR_NULL as i64;
    }
    let res = catch_unwind(AssertUnwindSafe(|| {
        let h = unsafe { &*handle };
        f(h)
    }));
    match res {
        Ok(v) => v,
        Err(_) => {
            set_last_error("panic at FFI boundary");
            LP_ERR_PANIC as i64
        }
    }
}
