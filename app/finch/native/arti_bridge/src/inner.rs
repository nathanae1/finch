//! Safe Rust core for the Arti bridge. Holds the [`TorClient`] and (when
//! running) a [`RunningOnionService`] + reverse proxy that forwards onion
//! traffic to the on-device HTTP server.
//!
//! The C-API in `lib.rs` is a thin shim over this module. Keep all
//! Tor-specific logic here so `unsafe` stays scoped to a single layer.

use std::path::PathBuf;
use std::sync::Arc;

use anyhow::{anyhow, Context, Result};
use arti_client::config::CfgPath;
use arti_client::{TorClient, TorClientConfig};
use safelog::DisplayRedacted;
use tokio::io::{copy_bidirectional, AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tor_hsrproxy::config::{
    Encapsulation, ProxyAction, ProxyConfigBuilder, ProxyPattern, ProxyRule, TargetAddr,
};
use tor_hsrproxy::OnionServiceReverseProxy;
use tor_hsservice::config::OnionServiceConfigBuilder;
use tor_hsservice::{HsNickname, RunningOnionService};
use tor_rtcompat::tokio::TokioRustlsRuntime;
use tor_socksproto::{
    Buffer, Handshake, NextStep, SocksAddr, SocksProxyHandshake, SocksStatus,
};

/// Stable nickname for the onion service keypair. Arti uses this to
/// namespace the descriptor signing key on disk under
/// `{data_dir}/hs-state/{nickname}`. Keep it constant across versions so
/// the .onion address persists.
const HS_NICKNAME: &str = "finch";

#[derive(Clone, Copy, Default)]
pub struct StatusSnapshot {
    pub bootstrap_percent: u32,
    pub circuit_count: u32,
    pub is_ready: bool,
    pub socks_port: u16,
}

pub struct Inner {
    runtime: TokioRustlsRuntime,
    client: TorClient<TokioRustlsRuntime>,
    #[allow(dead_code)]
    data_dir: PathBuf,
    onion: Option<OnionState>,
    socks_port: u16,
    socks_task: Option<tokio::task::JoinHandle<()>>,
}

struct OnionState {
    address: String,
    // Hold the running service so its background task stays alive. Drop
    // unpublishes the service.
    _service: Arc<RunningOnionService>,
    _proxy_task: tokio::task::JoinHandle<()>,
}

impl Inner {
    /// Bootstrap a new Tor client. Returns once the client object is
    /// constructed; bootstrap continues in the background.
    pub async fn start(data_dir: PathBuf) -> Result<Self> {
        std::fs::create_dir_all(&data_dir)
            .with_context(|| format!("create data dir {}", data_dir.display()))?;

        let cache_dir = data_dir.join("cache");
        let state_dir = data_dir.join("state");
        std::fs::create_dir_all(&cache_dir).ok();
        std::fs::create_dir_all(&state_dir).ok();

        let mut cfg = TorClientConfig::builder();
        cfg.storage()
            .cache_dir(CfgPath::new_literal(cache_dir.as_path()))
            .state_dir(CfgPath::new_literal(state_dir.as_path()));
        // iOS/Android sandbox the app's data directory at the OS level, but
        // the per-file unix permissions inherited from the system umask are
        // typically `o=rx` — which Arti's `fs-mistrust` rejects with
        // "Incorrect permissions: ... must be o-rx". Disable the unix-perm
        // check on mobile; the platform sandbox is the real boundary.
        cfg.storage().permissions().dangerously_trust_everyone();
        let cfg = cfg
            .build()
            .map_err(|e| anyhow!("build TorClientConfig: {e}"))?;

        let runtime = TokioRustlsRuntime::current()
            .context("acquire current tokio+rustls runtime")?;

        let client = TorClient::with_runtime(runtime.clone())
            .config(cfg)
            .create_bootstrapped()
            .await
            .context("bootstrap TorClient")?;

        // Spawn an in-process SOCKS5 listener bound to a kernel-assigned
        // loopback port. Dart's `http.Client` connects to this port and
        // we tunnel each accepted TCP stream out through `TorClient::connect`.
        let listener = TcpListener::bind("127.0.0.1:0")
            .await
            .context("bind SOCKS5 listener")?;
        let socks_port = listener
            .local_addr()
            .context("read SOCKS5 listener address")?
            .port();
        let socks_client = client.clone();
        let socks_task = tokio::spawn(run_socks_listener(socks_client, listener));

        Ok(Self {
            runtime,
            client,
            data_dir,
            onion: None,
            socks_port,
            socks_task: Some(socks_task),
        })
    }

    /// Launch (or reattach to) the onion service forwarding inbound
    /// traffic to `127.0.0.1:local_port`. Returns `<addr>.onion`.
    pub async fn create_onion_service(&mut self, local_port: u16) -> Result<String> {
        if let Some(existing) = &self.onion {
            return Ok(existing.address.clone());
        }

        let nickname: HsNickname = HS_NICKNAME
            .parse()
            .map_err(|e| anyhow!("parse onion nickname: {e}"))?;

        let svc_cfg = OnionServiceConfigBuilder::default()
            .nickname(nickname.clone())
            .build()
            .map_err(|e| anyhow!("build OnionServiceConfig: {e}"))?;

        let (service, request_stream) = self
            .client
            .launch_onion_service(svc_cfg)
            .map_err(|e| anyhow!("launch onion service: {e}"))?;

        // Reverse proxy: every inbound BEGIN cell on virtual port 80
        // becomes a TCP connection to 127.0.0.1:<local_port>.
        let mut proxy_cfg = ProxyConfigBuilder::default();
        proxy_cfg.proxy_ports().push(ProxyRule::new(
            ProxyPattern::one_port(80)
                .map_err(|e| anyhow!("build proxy pattern: {e}"))?,
            ProxyAction::Forward(
                Encapsulation::Simple,
                TargetAddr::Inet(format!("127.0.0.1:{local_port}").parse()?),
            ),
        ));
        let proxy = OnionServiceReverseProxy::new(
            proxy_cfg
                .build()
                .map_err(|e| anyhow!("build ProxyConfig: {e}"))?,
        );

        let proxy_runtime = self.runtime.clone();
        let proxy_task = tokio::spawn(async move {
            if let Err(e) = proxy
                .handle_requests(proxy_runtime, nickname, request_stream)
                .await
            {
                log::error!("onion reverse proxy failed: {e:?}");
            }
        });

        let address = service
            .onion_address()
            .ok_or_else(|| anyhow!("onion service has no published address yet"))?
            .display_unredacted()
            .to_string();

        self.onion = Some(OnionState {
            address: address.clone(),
            _service: service,
            _proxy_task: proxy_task,
        });
        Ok(address)
    }

    pub fn socks_port(&self) -> u16 {
        self.socks_port
    }

    pub fn status(&self) -> StatusSnapshot {
        let bs = self.client.bootstrap_status();
        let percent = (bs.as_frac() * 100.0).round().clamp(0.0, 100.0) as u32;
        let is_ready = bs.ready_for_traffic();
        // arti-client doesn't expose live circuit count via stable API.
        // We approximate: 3 once ready, 0 otherwise. 11b can swap this for
        // a real metric once we add a netdir observer.
        let circuit_count = if is_ready { 3 } else { 0 };
        StatusSnapshot {
            bootstrap_percent: percent,
            circuit_count,
            is_ready,
            socks_port: self.socks_port,
        }
    }

    pub async fn shutdown(&mut self) {
        if let Some(state) = self.onion.take() {
            state._proxy_task.abort();
            // Dropping `_service` triggers Arti to unpublish the descriptor
            // and stop accepting new INTRODUCE2 cells.
            drop(state._service);
        }
        if let Some(task) = self.socks_task.take() {
            task.abort();
        }
    }
}

/// Accept loop for the in-process SOCKS5 proxy. Each accepted connection
/// runs its handshake and tunnel on a fresh task so a slow circuit on one
/// stream doesn't block others.
async fn run_socks_listener(
    client: TorClient<TokioRustlsRuntime>,
    listener: TcpListener,
) {
    loop {
        let (stream, _) = match listener.accept().await {
            Ok(v) => v,
            Err(e) => {
                log::warn!("socks accept failed: {e}");
                continue;
            }
        };
        let client = client.clone();
        tokio::spawn(async move {
            if let Err(e) = handle_socks_conn(stream, client).await {
                log::debug!("socks conn ended: {e:?}");
            }
        });
    }
}

/// Drives one SOCKS5 client through the protocol handshake, opens a Tor
/// stream to the requested target, and bridges bytes between the two until
/// either side closes.
async fn handle_socks_conn(
    mut stream: TcpStream,
    client: TorClient<TokioRustlsRuntime>,
) -> Result<()> {
    let mut hs = SocksProxyHandshake::new();
    let mut buf = Buffer::new();

    let (request, leftover) = loop {
        match hs.step(&mut buf).map_err(|e| anyhow!("socks step: {e}"))? {
            NextStep::Send(data) => {
                stream.write_all(&data).await?;
            }
            NextStep::Recv(mut recv) => {
                let target = recv.buf();
                let n = stream.read(target).await?;
                if n == 0 {
                    return Err(anyhow!("client closed during SOCKS handshake"));
                }
                recv.note_received(n)
                    .map_err(|e| anyhow!("note_received: {e}"))?;
            }
            NextStep::Finished(fin) => {
                break fin.into_output_and_vec();
            }
        }
    };

    let (host, port) = match request.addr() {
        SocksAddr::Hostname(h) => (h.as_ref().to_string(), request.port()),
        SocksAddr::Ip(ip) => (ip.to_string(), request.port()),
    };

    let tor_stream = match client.connect((host.as_str(), port)).await {
        Ok(s) => s,
        Err(e) => {
            let reply = request
                .reply(SocksStatus::HOST_UNREACHABLE, None)
                .map_err(|err| anyhow!("build socks failure reply: {err}"))?;
            stream.write_all(&reply).await.ok();
            return Err(anyhow!("Tor connect to {host}:{port} failed: {e}"));
        }
    };

    let reply = request
        .reply(SocksStatus::SUCCEEDED, None)
        .map_err(|e| anyhow!("build socks success reply: {e}"))?;
    stream.write_all(&reply).await?;

    let mut tor_stream = tor_stream;
    if !leftover.is_empty() {
        // The client pipelined application bytes after its CONNECT request;
        // forward them as the first bytes of the tunnel before bridging.
        tor_stream.write_all(&leftover).await?;
    }
    copy_bidirectional(&mut stream, &mut tor_stream).await?;
    Ok(())
}
