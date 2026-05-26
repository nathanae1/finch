//! Internal state for [`super::LpHandle`].
//!
//! `Inner` owns a tokio runtime and drives a `Swarm<Behaviour>`. FFI calls
//! enqueue [`Cmd`]s on an unbounded mpsc; the event-loop task drains them
//! and also polls the swarm, posting CBOR-encoded events to Dart via the
//! Native Port set by [`super::lp_set_event_port`].

use std::collections::{HashMap, HashSet};
use std::io;
use std::str::FromStr;
use std::sync::atomic::{AtomicI64, AtomicU16, Ordering};
use std::sync::Arc;
use std::time::Duration;

use anyhow::{anyhow, Result};
use bytes::BytesMut;
use ciborium::value::Value as CborValue;
use futures::{AsyncReadExt, AsyncWriteExt, StreamExt};
use libp2p::core::transport::ListenerId;
use libp2p::swarm::SwarmEvent;
use libp2p::{
    identify,
    identity::{self, Keypair},
    multiaddr::Protocol,
    ping,
    swarm::NetworkBehaviour,
    Multiaddr, PeerId, Stream, StreamProtocol, Swarm,
};
use libp2p_stream as stream;
use parking_lot::RwLock;
use std::net::{Ipv4Addr, Ipv6Addr};
use tokio::sync::{mpsc, oneshot, Mutex};
use tokio::task::JoinHandle;
use zeroize::Zeroize;

use super::interfaces;

const STARLING_AGENT_VERSION: &str = "starling/1.0.0";
const STARLING_PROTOCOL_VERSION: &str = "/starling/1.0.0";

#[derive(NetworkBehaviour)]
pub struct Behaviour {
    pub identify: identify::Behaviour,
    pub ping: ping::Behaviour,
    pub stream: stream::Behaviour,
}

/// Result of a [`Cmd::DialDirect`] — Ok(conn_id) or error string.
pub type DialResult = Result<i64, String>;

/// One frame received from a stream, or terminator on close/error.
pub enum ReadEvent {
    Frame(Vec<u8>),
    Closed,
    Error(String),
}

pub struct StreamHandle {
    #[allow(dead_code)]
    pub remote_peer: PeerId,
    #[allow(dead_code)]
    pub protocol: String,
    /// Sender to the per-stream writer task. None after close.
    pub write_tx: mpsc::UnboundedSender<WriteCmd>,
    /// Inbound frames buffered by the per-stream reader task.
    pub read_rx: Mutex<mpsc::UnboundedReceiver<ReadEvent>>,
    /// Plan 11c — frame that didn't fit in the caller's read buffer
    /// last time. On the next `lp_stream_read` call we hand this back
    /// before pulling from `read_rx`, so a too-small first attempt
    /// doesn't drop the frame. Cleared once the caller's buffer is
    /// big enough to copy the bytes out.
    pub pending_frame: parking_lot::Mutex<Option<Vec<u8>>>,
    /// Set when the stream is half- or fully-closed.
    pub closed: parking_lot::Mutex<bool>,
}

pub enum WriteCmd {
    Frame {
        data: Vec<u8>,
        finish: bool,
        reply: oneshot::Sender<Result<(), String>>,
    },
    Close(oneshot::Sender<Result<(), String>>),
}

pub struct ConnRecord {
    pub peer: PeerId,
}

/// Commands sent from FFI threads to the swarm-owning event loop.
pub enum Cmd {
    /// Dial `peer` over `addrs`. The behaviour adds each addr to the
    /// peer's address book then issues a Swarm::dial.
    DialDirect {
        peer: PeerId,
        addrs: Vec<Multiaddr>,
        timeout: Duration,
        reply: oneshot::Sender<DialResult>,
    },
    /// Plan 11c — fired by the per-dial watchdog task when the
    /// configured timeout elapses without a ConnectionEstablished /
    /// OutgoingConnectionError for `peer`. The event loop removes the
    /// `pending_dials` entry (if still present) and notifies the caller
    /// with `Err("dial timed out")`, then leaves the swarm's own
    /// dial-state machine to clean up.
    DialTimeout {
        peer: PeerId,
    },
    /// Add a discovered external address (e.g., a peer's observation
    /// embedded in a signaling reply, or an interface-watcher event).
    /// Filtered through [`insert_if_routable`] before insertion.
    AddObservedAddr {
        addr: Multiaddr,
        reply: oneshot::Sender<Result<(), String>>,
    },
    /// Register `protocol` for inbound streams. Spawns an accept task.
    RegisterInbound {
        protocol: StreamProtocol,
        reply: oneshot::Sender<Result<(), String>>,
    },
    /// Stop the swarm and shut everything down.
    Shutdown,
}

pub struct Inner {
    pub keypair: Keypair,
    pub local_peer_id: PeerId,
    pub event_port: AtomicI64,
    pub cmd_tx: mpsc::UnboundedSender<Cmd>,
    /// Receiver held until the event loop is spawned in `start_listen`.
    pub cmd_rx: parking_lot::Mutex<Option<mpsc::UnboundedReceiver<Cmd>>>,
    pub runtime: tokio::runtime::Runtime,
    pub task_handle: parking_lot::Mutex<Option<JoinHandle<()>>>,
    pub conns: RwLock<HashMap<i64, ConnRecord>>,
    pub conn_counter: AtomicI64,
    pub streams: RwLock<HashMap<i64, Arc<StreamHandle>>>,
    pub stream_counter: AtomicI64,
    pub inbound_handlers: RwLock<HashSet<String>>,
    pub observed_addrs: RwLock<HashSet<Multiaddr>>,
    pub stream_control: Mutex<Option<stream::Control>>,
    pub listening: parking_lot::Mutex<bool>,
    /// Plan 11c — port the v6 QUIC listener bound to (set from the
    /// first `SwarmEvent::NewListenAddr` with an Ip6 prefix). The
    /// interfaces enumerator combines this with each global v6 address
    /// to construct routable multiaddrs for our observed-addrs cache.
    /// `0` until the listener has bound.
    pub listen_v6_port: AtomicU16,
}

impl Inner {
    /// Build a new Inner from a 32-byte Ed25519 seed. The Swarm is
    /// constructed but no listener is bound and no event loop is spawned
    /// yet — that happens in [`Inner::start_listen`].
    pub fn new(seed: &[u8; 32]) -> Result<Arc<Self>> {
        let mut seed_copy = *seed;
        let keypair = identity::Keypair::ed25519_from_bytes(&mut seed_copy)
            .map_err(|e| anyhow!("ed25519 keypair: {e}"))?;
        seed_copy.zeroize();
        let local_peer_id = keypair.public().to_peer_id();

        let runtime = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("libp2p-bridge")
            .enable_all()
            .build()
            .map_err(|e| anyhow!("tokio runtime: {e}"))?;

        let (cmd_tx, cmd_rx) = mpsc::unbounded_channel::<Cmd>();

        Ok(Arc::new(Self {
            keypair,
            local_peer_id,
            event_port: AtomicI64::new(0),
            cmd_tx,
            cmd_rx: parking_lot::Mutex::new(Some(cmd_rx)),
            runtime,
            task_handle: parking_lot::Mutex::new(None),
            conns: RwLock::new(HashMap::new()),
            conn_counter: AtomicI64::new(0),
            streams: RwLock::new(HashMap::new()),
            stream_counter: AtomicI64::new(0),
            inbound_handlers: RwLock::new(HashSet::new()),
            observed_addrs: RwLock::new(HashSet::new()),
            stream_control: Mutex::new(None),
            listening: parking_lot::Mutex::new(false),
            listen_v6_port: AtomicU16::new(0),
        }))
    }

    /// Spawn the swarm + event loop. Idempotent — second call is a no-op.
    pub fn start_listen(self: &Arc<Self>) -> Result<()> {
        let cmd_rx = {
            let mut lst = self.listening.lock();
            if *lst {
                return Ok(());
            }
            let cmd_rx = self
                .cmd_rx
                .lock()
                .take()
                .ok_or_else(|| anyhow!("cmd receiver already taken"))?;
            *lst = true;
            cmd_rx
        };

        let inner = Arc::clone(self);
        let keypair = self.keypair.clone();
        let task = self.runtime.spawn(async move {
            if let Err(e) = run(inner, keypair, cmd_rx).await {
                log::error!("libp2p event loop terminated: {e:#}");
            }
        });
        *self.task_handle.lock() = Some(task);
        Ok(())
    }

    pub fn send_cmd(&self, cmd: Cmd) -> Result<(), String> {
        self.cmd_tx.send(cmd).map_err(|_| "event loop closed".into())
    }

    /// Block the current FFI thread until the runtime returns a result
    /// from the event loop. Spawns a oneshot, sends the cmd, blocks on
    /// recv with a timeout.
    pub fn block_on_cmd<T: Send + 'static>(
        &self,
        cmd_fn: impl FnOnce(oneshot::Sender<T>) -> Cmd,
        timeout: Duration,
    ) -> Result<T, String> {
        let (tx, rx) = oneshot::channel::<T>();
        let cmd = cmd_fn(tx);
        self.send_cmd(cmd)?;
        self.runtime
            .block_on(async move {
                tokio::time::timeout(timeout, rx)
                    .await
                    .map_err(|_| "timeout waiting on event loop".to_string())?
                    .map_err(|_| "event loop dropped reply channel".to_string())
            })
    }

    pub fn allocate_conn_id(&self, peer: PeerId) -> i64 {
        let id = self.conn_counter.fetch_add(1, Ordering::SeqCst) + 1;
        self.conns.write().insert(id, ConnRecord { peer });
        id
    }

    pub fn allocate_stream_id(&self, handle: Arc<StreamHandle>) -> i64 {
        let id = self.stream_counter.fetch_add(1, Ordering::SeqCst) + 1;
        self.streams.write().insert(id, handle);
        id
    }

    pub fn drop_stream(&self, stream_id: i64) {
        self.streams.write().remove(&stream_id);
    }

    pub fn shutdown(self: &Arc<Self>) {
        let _ = self.cmd_tx.send(Cmd::Shutdown);
        let handle = self.task_handle.lock().take();
        if let Some(h) = handle {
            // Give the task a moment to flush, then abort if it hangs.
            h.abort();
        }
    }
}

/// The actual event-loop driver. Owns the Swarm.
async fn run(
    inner: Arc<Inner>,
    keypair: Keypair,
    mut cmd_rx: mpsc::UnboundedReceiver<Cmd>,
) -> Result<()> {
    let mut swarm = build_swarm(keypair)?;
    let control = swarm.behaviour().stream.new_control();
    *inner.stream_control.lock().await = Some(control.clone());

    // Bind both v4 and v6 UDP/QUIC listeners. Plan 11c — IPv6 is the
    // single biggest NAT-traversal win for cellular: most carriers
    // (AT&T, T-Mobile, Verizon, most EU) assign a globally-routable v6
    // and apply a stateful firewall with endpoint-independent filtering,
    // which simultaneous-open punches the same way WireGuard / Tailscale
    // / WhatsApp do. The carrier-assigned v6 is our *real* public
    // address — no NAT, no reflection needed.
    swarm
        .listen_on("/ip4/0.0.0.0/udp/0/quic-v1".parse()?)
        .map_err(|e| anyhow!("listen_on v4: {e}"))?;
    swarm
        .listen_on("/ip6/::/udp/0/quic-v1".parse()?)
        .map_err(|e| anyhow!("listen_on v6: {e}"))?;

    // Plan 11c — instead of the (broken) STUN probe, we enumerate the
    // device's routable v6 addresses per interface and feed them
    // through the same `Cmd::AddObservedAddr` path peers use. On
    // network-change events (`if-watch`) we re-enumerate and update.
    interfaces::spawn_v6_enumerator(Arc::clone(&inner));

    // Pending dials keyed by remote peer; on ConnectionEstablished or
    // OutgoingConnectionError we pop the entry and send the reply.
    // Plan 11c — paired with a per-dial watchdog task that sends
    // `Cmd::DialTimeout` to evict orphaned entries; without it, a dial
    // whose result never reaches the swarm (e.g., silently dropped UDP)
    // would leak an entry until process exit.
    let mut pending_dials: HashMap<PeerId, oneshot::Sender<DialResult>> = HashMap::new();
    let mut listeners: HashSet<ListenerId> = HashSet::new();

    loop {
        tokio::select! {
            event = swarm.next() => {
                let Some(event) = event else { break };
                handle_swarm_event(&inner, &mut swarm, event, &mut pending_dials, &mut listeners).await;
            }
            cmd = cmd_rx.recv() => {
                match cmd {
                    Some(Cmd::Shutdown) | None => break,
                    Some(other) => handle_cmd(&inner, &mut swarm, &control, other, &mut pending_dials).await,
                }
            }
        }
    }
    Ok(())
}

fn build_swarm(keypair: Keypair) -> Result<Swarm<Behaviour>> {
    let swarm = libp2p::SwarmBuilder::with_existing_identity(keypair)
        .with_tokio()
        .with_quic()
        .with_behaviour(|key| Behaviour {
            identify: identify::Behaviour::new(identify::Config::new(
                STARLING_PROTOCOL_VERSION.to_string(),
                key.public(),
            ).with_agent_version(STARLING_AGENT_VERSION.to_string())),
            ping: ping::Behaviour::default(),
            stream: stream::Behaviour::new(),
        })
        .map_err(|e| anyhow!("with_behaviour: {e}"))?
        .with_swarm_config(|c| c.with_idle_connection_timeout(Duration::from_secs(300)))
        .build();
    Ok(swarm)
}

async fn handle_swarm_event(
    inner: &Arc<Inner>,
    _swarm: &mut Swarm<Behaviour>,
    event: SwarmEvent<BehaviourEvent>,
    pending_dials: &mut HashMap<PeerId, oneshot::Sender<DialResult>>,
    listeners: &mut HashSet<ListenerId>,
) {
    match event {
        SwarmEvent::NewListenAddr { address, listener_id } => {
            listeners.insert(listener_id);
            // Capture the bound UDP port per family so the interfaces
            // enumerator (Plan 11c) can combine it with the OS-assigned
            // per-interface IPs to form routable multiaddrs. The
            // unspecified address itself is never published — the
            // routable filter rejects it.
            if let Some(port) = bound_udp_port(&address) {
                if has_ip6(&address) {
                    inner.listen_v6_port.store(port, Ordering::Release);
                }
            }
            if insert_if_routable(inner, address.clone()) {
                post_event(inner, cbor_observed_addr_changed(&address));
            }
        }
        SwarmEvent::ConnectionEstablished { peer_id, .. } => {
            post_event(inner, cbor_peer_connected(&peer_id));
            if let Some(reply) = pending_dials.remove(&peer_id) {
                let conn_id = inner.allocate_conn_id(peer_id);
                let _ = reply.send(Ok(conn_id));
            }
        }
        SwarmEvent::ConnectionClosed { peer_id, .. } => {
            // Remove all conn records for this peer.
            inner.conns.write().retain(|_, rec| rec.peer != peer_id);
            post_event(inner, cbor_peer_disconnected(&peer_id));
        }
        SwarmEvent::OutgoingConnectionError { peer_id, error, .. } => {
            if let Some(peer) = peer_id {
                if let Some(reply) = pending_dials.remove(&peer) {
                    let _ = reply.send(Err(error.to_string()));
                }
            }
        }
        SwarmEvent::Behaviour(BehaviourEvent::Identify(identify::Event::Received {
            peer_id, info, ..
        })) => {
            post_event(
                inner,
                cbor_identify_received(&peer_id, &info.observed_addr, &info.listen_addrs),
            );
            // The peer's observation IS our most reliable post-connect
            // source of a real external address (correct IP + port for
            // the QUIC socket). Filter through the routable check just
            // in case the peer is on our LAN and reports a private addr.
            insert_if_routable(inner, info.observed_addr.clone());
        }
        SwarmEvent::ExternalAddrConfirmed { address } => {
            if insert_if_routable(inner, address.clone()) {
                post_event(inner, cbor_observed_addr_changed(&address));
            }
        }
        _ => {}
    }
}

async fn handle_cmd(
    inner: &Arc<Inner>,
    swarm: &mut Swarm<Behaviour>,
    control: &stream::Control,
    cmd: Cmd,
    pending_dials: &mut HashMap<PeerId, oneshot::Sender<DialResult>>,
) {
    match cmd {
        Cmd::DialDirect {
            peer,
            addrs,
            timeout,
            reply,
        } => {
            for addr in &addrs {
                swarm.add_peer_address(peer, addr.clone());
            }
            let dial = libp2p::swarm::dial_opts::DialOpts::peer_id(peer)
                .addresses(addrs)
                .build();
            match swarm.dial(dial) {
                Ok(_) => {
                    pending_dials.insert(peer, reply);
                    // Per-dial watchdog. Sends a `Cmd::DialTimeout`
                    // back through the event-loop's own channel after
                    // `timeout` so all swarm-touching work stays on
                    // the loop task (no concurrent access to
                    // `pending_dials`). Idempotent: if a swarm event
                    // already cleared the entry, the timeout handler
                    // is a no-op.
                    let cmd_tx = inner.cmd_tx.clone();
                    tokio::spawn(async move {
                        tokio::time::sleep(timeout).await;
                        let _ = cmd_tx.send(Cmd::DialTimeout { peer });
                    });
                }
                Err(e) => {
                    let _ = reply.send(Err(format!("dial: {e}")));
                }
            }
        }
        Cmd::DialTimeout { peer } => {
            if let Some(reply) = pending_dials.remove(&peer) {
                let _ = reply.send(Err("dial timed out".into()));
            }
        }
        Cmd::AddObservedAddr { addr, reply } => {
            // Surface the address to the swarm's external-addr set if
            // it passes the routability filter; same for our local
            // observed-addrs cache. Untouched addrs (loopback /
            // link-local / unspecified) are dropped silently — they
            // would only mislead peers trying to dial us back.
            if insert_if_routable(inner, addr.clone()) {
                swarm.add_external_address(addr.clone());
                post_event(inner, cbor_observed_addr_changed(&addr));
            }
            let _ = reply.send(Ok(()));
        }
        Cmd::RegisterInbound { protocol, reply } => {
            match control.clone().accept(protocol.clone()) {
                Ok(incoming) => {
                    inner
                        .inbound_handlers
                        .write()
                        .insert(protocol.to_string());
                    spawn_inbound_acceptor(Arc::clone(inner), protocol.to_string(), incoming);
                    let _ = reply.send(Ok(()));
                }
                Err(e) => {
                    let _ = reply.send(Err(format!("accept: {e}")));
                }
            }
        }
        Cmd::Shutdown => {
            // Handled in run() loop; here for completeness.
        }
    }
}

/// Insert `addr` into `inner.observed_addrs` iff it is a *routable*
/// multiaddr — meaning a peer could in principle reach us by dialing
/// it. Rejects:
///   - unspecified addresses (`0.0.0.0`, `::`) — these are *bind*
///     addresses, not endpoints; advertising them to a peer just
///     wastes their dial budget.
///   - loopback (`127.0.0.0/8`, `::1`) — never useful externally.
///   - IPv4 link-local (`169.254.0.0/16`) and IPv6 unicast link-local
///     (`fe80::/10`) — only valid on the originating segment.
///
/// LAN-private v4 (`10/8`, `172.16/12`, `192.168/16`) and ULA v6
/// (`fc00::/7`) are *kept* — they are exactly what we want for
/// same-network peers to dial. Returns whether the address was kept.
fn insert_if_routable(inner: &Arc<Inner>, addr: Multiaddr) -> bool {
    let keep = match addr.iter().next() {
        Some(Protocol::Ip4(a)) => is_routable_v4(a),
        Some(Protocol::Ip6(a)) => is_routable_v6(a),
        _ => false, // dns4 / dns6 / etc. don't appear in our flow today
    };
    if keep {
        inner.observed_addrs.write().insert(addr);
    }
    keep
}

fn is_routable_v4(a: Ipv4Addr) -> bool {
    !(a.is_unspecified() || a.is_loopback() || a.is_link_local())
}

fn is_routable_v6(a: Ipv6Addr) -> bool {
    !(a.is_unspecified() || a.is_loopback() || a.is_unicast_link_local())
}

/// Returns the UDP port from a `/ipX/.../udp/<port>/...` multiaddr, if
/// present. Used by the listener-event handler to record the bound port
/// per family.
fn bound_udp_port(addr: &Multiaddr) -> Option<u16> {
    for p in addr.iter() {
        if let Protocol::Udp(port) = p {
            return Some(port);
        }
    }
    None
}

/// Whether `addr` starts with an `Ip6` protocol element.
fn has_ip6(addr: &Multiaddr) -> bool {
    matches!(addr.iter().next(), Some(Protocol::Ip6(_)))
}

/// Plan 11c — exposed to the `interfaces` module so it can feed
/// per-interface v6 addresses into the same filtered observed_addrs set
/// the swarm uses. Public-in-crate; the FFI surface never calls this
/// directly.
pub(crate) fn insert_observed_if_routable(inner: &Arc<Inner>, addr: Multiaddr) -> bool {
    insert_if_routable(inner, addr)
}

/// Spawn an acceptor task per registered protocol. Each accepted stream
/// gets a stream_id, two IO tasks, and a `inbound_stream` event posted to
/// Dart.
fn spawn_inbound_acceptor(
    inner: Arc<Inner>,
    protocol: String,
    mut incoming: stream::IncomingStreams,
) {
    tokio::spawn(async move {
        while let Some((peer, raw_stream)) = incoming.next().await {
            let handle = spawn_stream_io(Arc::clone(&inner), peer, protocol.clone(), raw_stream);
            let stream_id = inner.allocate_stream_id(handle);
            post_event(
                &inner,
                cbor_inbound_stream(&peer, &protocol, stream_id),
            );
        }
    });
}

/// Spawn a per-stream reader+writer task pair. Returns the handle stored
/// in `inner.streams`.
fn spawn_stream_io(
    _inner: Arc<Inner>,
    peer: PeerId,
    protocol: String,
    raw_stream: Stream,
) -> Arc<StreamHandle> {
    let (write_tx, mut write_rx) = mpsc::unbounded_channel::<WriteCmd>();
    let (read_tx, read_rx) = mpsc::unbounded_channel::<ReadEvent>();

    let handle = Arc::new(StreamHandle {
        remote_peer: peer,
        protocol,
        write_tx,
        read_rx: Mutex::new(read_rx),
        pending_frame: parking_lot::Mutex::new(None),
        closed: parking_lot::Mutex::new(false),
    });

    let (mut reader, mut writer) = raw_stream.split();

    // Reader task: read length-delimited frames forever.
    let read_tx_clone = read_tx.clone();
    tokio::spawn(async move {
        let mut accum = BytesMut::new();
        loop {
            match read_one_frame(&mut reader, &mut accum).await {
                Ok(frame) => {
                    if read_tx_clone.send(ReadEvent::Frame(frame)).is_err() {
                        break;
                    }
                }
                Err(e) if matches!(e.kind(), io::ErrorKind::UnexpectedEof) => {
                    let _ = read_tx_clone.send(ReadEvent::Closed);
                    break;
                }
                Err(e) => {
                    let _ = read_tx_clone.send(ReadEvent::Error(e.to_string()));
                    break;
                }
            }
        }
    });

    // Writer task: process WriteCmds.
    let handle_for_closed = Arc::clone(&handle);
    tokio::spawn(async move {
        while let Some(cmd) = write_rx.recv().await {
            match cmd {
                WriteCmd::Frame {
                    data,
                    finish,
                    reply,
                } => {
                    let result = write_one_frame(&mut writer, &data).await;
                    if let Err(e) = result {
                        let _ = reply.send(Err(e.to_string()));
                        break;
                    }
                    if finish {
                        let _ = writer.close().await;
                        *handle_for_closed.closed.lock() = true;
                    }
                    let _ = reply.send(Ok(()));
                }
                WriteCmd::Close(reply) => {
                    let _ = writer.close().await;
                    *handle_for_closed.closed.lock() = true;
                    let _ = reply.send(Ok(()));
                    break;
                }
            }
        }
    });

    handle
}

/// Read one length-delimited frame from `reader` using `accum` as a
/// persistent buffer for partial reads.
async fn read_one_frame<R>(reader: &mut R, accum: &mut BytesMut) -> io::Result<Vec<u8>>
where
    R: futures::AsyncRead + Unpin,
{
    // Ensure we have at least 4 bytes for the length prefix.
    while accum.len() < 4 {
        let mut buf = [0u8; 4096];
        let n = reader.read(&mut buf).await?;
        if n == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "eof"));
        }
        accum.extend_from_slice(&buf[..n]);
    }
    let len = u32::from_be_bytes([accum[0], accum[1], accum[2], accum[3]]) as usize;
    while accum.len() < 4 + len {
        let mut buf = [0u8; 4096];
        let n = reader.read(&mut buf).await?;
        if n == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "eof mid-frame"));
        }
        accum.extend_from_slice(&buf[..n]);
    }
    let frame = accum[4..4 + len].to_vec();
    let _ = accum.split_to(4 + len);
    Ok(frame)
}

async fn write_one_frame<W>(writer: &mut W, data: &[u8]) -> io::Result<()>
where
    W: futures::AsyncWrite + Unpin,
{
    let len = u32::try_from(data.len())
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "frame too large"))?;
    writer.write_all(&len.to_be_bytes()).await?;
    writer.write_all(data).await?;
    writer.flush().await?;
    Ok(())
}

// -------------------------- Outbound stream API ---------------------------

impl Inner {
    /// Open a libp2p outbound stream from any tokio task. Returns the new
    /// FFI stream id.
    pub async fn open_outbound_stream(
        self: &Arc<Self>,
        conn_id: i64,
        protocol_str: String,
    ) -> Result<i64, String> {
        let peer = {
            let conns = self.conns.read();
            conns
                .get(&conn_id)
                .ok_or_else(|| format!("unknown conn_id {conn_id}"))?
                .peer
        };
        let protocol = StreamProtocol::try_from_owned(protocol_str.clone())
            .map_err(|e| format!("bad protocol: {e}"))?;
        let control = {
            let guard = self.stream_control.lock().await;
            guard
                .as_ref()
                .ok_or_else(|| "stream control not ready — call lp_listen first".to_string())?
                .clone()
        };
        let raw_stream = control
            .clone()
            .open_stream(peer, protocol)
            .await
            .map_err(|e| format!("open_stream: {e}"))?;
        let handle = spawn_stream_io(Arc::clone(self), peer, protocol_str, raw_stream);
        Ok(self.allocate_stream_id(handle))
    }

    /// Parse the address book and dial. Returns conn_id.
    pub async fn dial_direct(
        self: &Arc<Self>,
        peer: PeerId,
        addrs: Vec<Multiaddr>,
        timeout: Duration,
    ) -> Result<i64, String> {
        // If we already have a connection to this peer, return its conn_id.
        if let Some(existing) = self
            .conns
            .read()
            .iter()
            .find_map(|(id, rec)| (rec.peer == peer).then_some(*id))
        {
            return Ok(existing);
        }
        let (tx, rx) = oneshot::channel::<DialResult>();
        self.send_cmd(Cmd::DialDirect {
            peer,
            addrs,
            timeout,
            reply: tx,
        })?;
        match tokio::time::timeout(timeout, rx).await {
            Ok(Ok(result)) => result,
            Ok(Err(_)) => Err("dial reply dropped".into()),
            Err(_) => Err("dial timed out".into()),
        }
    }
}

// ---------------- CBOR event encoding (Plan 11a wire format) ----------------

fn post_event(inner: &Arc<Inner>, payload: Vec<u8>) {
    let port = inner.event_port.load(Ordering::Acquire);
    if port == 0 {
        return;
    }
    let isolate = allo_isolate::Isolate::new(port);
    isolate.post(payload);
}

fn cbor_map(entries: &[(&str, CborValue)]) -> Vec<u8> {
    let map = CborValue::Map(
        entries
            .iter()
            .map(|(k, v)| (CborValue::Text((*k).to_string()), v.clone()))
            .collect(),
    );
    let mut out = Vec::new();
    ciborium::into_writer(&map, &mut out).expect("cbor encode");
    out
}

fn cbor_peer_connected(peer: &PeerId) -> Vec<u8> {
    cbor_map(&[
        ("type", CborValue::Text("peer_connected".into())),
        ("peer_id", CborValue::Text(peer.to_base58())),
    ])
}

fn cbor_peer_disconnected(peer: &PeerId) -> Vec<u8> {
    cbor_map(&[
        ("type", CborValue::Text("peer_disconnected".into())),
        ("peer_id", CborValue::Text(peer.to_base58())),
    ])
}

fn cbor_identify_received(peer: &PeerId, observed: &Multiaddr, listen: &[Multiaddr]) -> Vec<u8> {
    let listen = CborValue::Array(listen.iter().map(|m| CborValue::Bytes(m.to_vec())).collect());
    cbor_map(&[
        ("type", CborValue::Text("identify_received".into())),
        ("peer_id", CborValue::Text(peer.to_base58())),
        ("observed_addr", CborValue::Bytes(observed.to_vec())),
        ("listen_addrs", listen),
    ])
}

fn cbor_observed_addr_changed(addr: &Multiaddr) -> Vec<u8> {
    cbor_map(&[
        ("type", CborValue::Text("observed_addr_changed".into())),
        ("multiaddr", CborValue::Bytes(addr.to_vec())),
    ])
}

fn cbor_inbound_stream(peer: &PeerId, protocol: &str, stream_id: i64) -> Vec<u8> {
    cbor_map(&[
        ("type", CborValue::Text("inbound_stream".into())),
        ("peer_id", CborValue::Text(peer.to_base58())),
        ("protocol", CborValue::Text(protocol.into())),
        ("stream_id", CborValue::Integer(stream_id.into())),
    ])
}

// ---------------- CBOR helpers used by FFI surface in lib.rs ----------------

/// Parse a CBOR list-of-byte-strings into `Vec<Multiaddr>`.
pub fn decode_addrs_cbor(bytes: &[u8]) -> Result<Vec<Multiaddr>, String> {
    let value: CborValue =
        ciborium::from_reader(bytes).map_err(|e| format!("cbor parse: {e}"))?;
    let list = match value {
        CborValue::Array(a) => a,
        _ => return Err("expected cbor array of multiaddr bytes".into()),
    };
    let mut out = Vec::with_capacity(list.len());
    for v in list {
        let bytes = match v {
            CborValue::Bytes(b) => b,
            _ => return Err("expected cbor bytes element".into()),
        };
        out.push(Multiaddr::try_from(bytes).map_err(|e| format!("bad multiaddr: {e}"))?);
    }
    Ok(out)
}

/// Encode the current observed-addrs set as a CBOR list-of-byte-strings.
pub fn encode_observed_addrs_cbor(addrs: &HashSet<Multiaddr>) -> Vec<u8> {
    let arr = CborValue::Array(addrs.iter().map(|m| CborValue::Bytes(m.to_vec())).collect());
    let mut out = Vec::new();
    ciborium::into_writer(&arr, &mut out).expect("cbor encode");
    out
}

pub fn parse_peer_id(s: &str) -> Result<PeerId, String> {
    PeerId::from_str(s).map_err(|e| format!("bad peer id: {e}"))
}
