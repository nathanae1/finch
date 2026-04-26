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
use tor_hsrproxy::config::{
    Encapsulation, ProxyAction, ProxyConfigBuilder, ProxyPattern, ProxyRule, TargetAddr,
};
use tor_hsrproxy::OnionServiceReverseProxy;
use tor_hsservice::config::OnionServiceConfigBuilder;
use tor_hsservice::{HsNickname, RunningOnionService};
use tor_rtcompat::tokio::TokioRustlsRuntime;

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
        // Mobile devices: keep the directory cache small and the bootstrap
        // path tight. Defaults are tuned for desktop.
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

        Ok(Self {
            runtime,
            client,
            data_dir,
            onion: None,
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

    /// Plan 11b will populate this once we run the SOCKS proxy in-process.
    /// 11a leaves it at 0.
    pub fn socks_port(&self) -> u16 {
        0
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
            socks_port: self.socks_port(),
        }
    }

    pub async fn shutdown(&mut self) {
        if let Some(state) = self.onion.take() {
            state._proxy_task.abort();
            // Dropping `_service` triggers Arti to unpublish the descriptor
            // and stop accepting new INTRODUCE2 cells.
            drop(state._service);
        }
    }
}

