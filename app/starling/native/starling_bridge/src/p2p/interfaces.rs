//! Plan 11c — per-interface IPv6 address enumerator.
//!
//! rust-libp2p's QUIC listener binds the unspecified address (`::`) and
//! emits a `NewListenAddr` with that same unspecified address — it does
//! NOT expand `::` to the per-interface IPs the OS has assigned (the
//! way some transports do). Without explicit enumeration, our
//! `observed_addrs` set never contains a routable v6, and peers
//! coordinating a libp2p-direct upgrade have nothing useful to dial.
//!
//! This module spawns a task that:
//!   1. Constructs an `if-watch` `IfWatcher` (tokio variant).
//!   2. Drains the initial snapshot of `IfEvent::Up(IpNet)` events
//!      (one per locally-assigned interface address) and combines each
//!      *routable* v6 with the bound QUIC v6 port from
//!      [`Inner::listen_v6_port`] to form `/ip6/<addr>/udp/<port>/quic-v1`
//!      multiaddrs. Inserts each through [`super::inner::insert_observed_if_routable`]
//!      so the same filter rejects loopback / link-local / unspecified
//!      that everything else uses.
//!   3. Continues to consume `IfEvent::Up` and `IfEvent::Down` events
//!      for the life of the bridge, keeping `observed_addrs` accurate
//!      as the device moves between WiFi / cellular / VPN / airplane
//!      modes. (Down events remove the matching multiaddr.)
//!
//! IPv4 is *not* enumerated here. v4 LAN reachability flows through
//! mDNS + the LAN tier of the reachability monitor; the libp2p-direct
//! WAN path only matters for v6 (and full-cone v4 NATs where the
//! peer's `Identify` reflection populates the observed addr post-
//! connect).

use std::sync::Arc;
use std::time::Duration;

use futures::StreamExt;
use if_watch::{IfEvent, IpNet};
use libp2p::{multiaddr::Protocol, Multiaddr};
use std::sync::atomic::Ordering;

use super::inner::{insert_observed_if_routable, Inner};

/// Spawn the v6 interface enumerator. Idempotent at the caller's
/// discretion — spawn at most once per [`Inner`] lifetime, immediately
/// after the swarm has been built.
pub(crate) fn spawn_v6_enumerator(inner: Arc<Inner>) {
    tokio::spawn(async move {
        // Some platforms (notably iOS in tests with no network) fail
        // `IfWatcher::new`. Log and bail — `observed_addrs` will be
        // empty but the bridge still works on LAN / via Identify.
        let mut watcher = match if_watch::tokio::IfWatcher::new() {
            Ok(w) => w,
            Err(e) => {
                log::warn!("interfaces: IfWatcher::new failed: {e}");
                return;
            }
        };

        // The v6 listener binds asynchronously; the port is set from
        // the first `NewListenAddr` with an Ip6 prefix. Hold incoming
        // events until we know the port, then drain.
        let mut buffered: Vec<IpNet> = Vec::new();

        loop {
            let port = inner.listen_v6_port.load(Ordering::Acquire);

            tokio::select! {
                event = watcher.next() => {
                    match event {
                        Some(Ok(IfEvent::Up(net))) => {
                            if port == 0 {
                                buffered.push(net);
                                continue;
                            }
                            announce_if_routable(&inner, &net, port);
                        }
                        Some(Ok(IfEvent::Down(net))) => {
                            if port == 0 { continue; }
                            forget(&inner, &net, port);
                        }
                        Some(Err(e)) => {
                            log::warn!("interfaces: watcher error: {e}");
                        }
                        None => break, // watcher closed; nothing more to do
                    }
                }
                // While we don't have a port yet, poll periodically and
                // drain the buffer once the listener binds.
                _ = tokio::time::sleep(Duration::from_millis(250)), if port == 0 => {
                    let new_port = inner.listen_v6_port.load(Ordering::Acquire);
                    if new_port != 0 {
                        for net in buffered.drain(..) {
                            announce_if_routable(&inner, &net, new_port);
                        }
                    }
                }
            }
        }
    });
}

fn announce_if_routable(inner: &Arc<Inner>, net: &IpNet, port: u16) {
    let IpNet::V6(v6) = net else { return };
    let ip = v6.addr();
    let ma: Multiaddr = Multiaddr::empty()
        .with(Protocol::Ip6(ip))
        .with(Protocol::Udp(port))
        .with(Protocol::QuicV1);
    insert_observed_if_routable(inner, ma);
}

fn forget(inner: &Arc<Inner>, net: &IpNet, port: u16) {
    let IpNet::V6(v6) = net else { return };
    let ip = v6.addr();
    let ma: Multiaddr = Multiaddr::empty()
        .with(Protocol::Ip6(ip))
        .with(Protocol::Udp(port))
        .with(Protocol::QuicV1);
    inner.observed_addrs.write().remove(&ma);
}
