# Relay

The relay is an optional, zero-knowledge service that makes your encrypted content available 24/7. It stores only its owner's data and serves it to their followers. It never fetches, proxies, or aggregates content from other users.

The relay is **not required**. Finch works phone-to-phone. The relay is the first step up the self-hosting gradient — it solves the availability problem (your content is reachable even when your phone is off) without requiring any technical knowledge in its simplest form.

## Two Deployment Modes

### 1. Spare Device Mode (zero setup)

Install Finch on any spare device (old phone, old tablet), pair with your main device, flip a toggle. It becomes your always-on relay.

- Runs the same on-device HTTP server + Tor onion service already built into the Finch app
- Reachable via `.onion` address — no port forwarding, no domain, no DNS
- Leave on WiFi, plugged in
- Uses the device's storage (typically 64-128GB+)
- **Best for**: everyone. Zero technical knowledge required.

**Pairing flow:**
1. Main phone: Settings > "Set Up Relay" > shows QR code with owner pubkey + auth token
2. Spare device: install Finch > "Run as Relay" > scan QR
3. Spare device receives owner pubkey, starts Tor onion service, reports `.onion` address back to main phone
4. Main phone updates its connection card to include the relay endpoint
5. Main phone begins pushing encrypted content to the relay

**What the relay device shows:**
- Minimal dashboard: storage used/available, last push received, connection status, onion address
- No feed, no content creation, no follow management — just relay status
- Option to stop relay mode and convert back to a normal Finch device

**Resource management:**
- Android: foreground service with persistent notification ("Finch Relay active") — reliable
- iOS: limited by background execution rules — Android strongly preferred for relay duty
- Storage limit configurable (defaults to 50% of available space)

### 2. Standalone Server (Rust binary)

For self-hosters: a headless Rust binary that runs on a Raspberry Pi, NAS, VPS, Proxmox container, or any Linux/macOS/Windows machine.

- Reachable via domain + TLS (traditional hosting) or Tor onion (no domain needed)
- **Best for**: self-hosters, power users, anyone who already runs infrastructure

## Design Principles

- **Zero-knowledge**: Stores encrypted blobs it cannot decrypt. Sees only metadata (pubkey, timestamps, sizes).
- **Single-user**: Each relay serves exactly one Finch identity. No multi-tenancy.
- **Push-only ingest**: Only the owner can write. Followers can only read.
- **Stateless auth**: Requests authenticated via Ed25519 signatures — no sessions, no tokens.

## API

Implements the Finch sync protocol endpoints:

### Public (no auth required)

| Endpoint | Description |
|----------|-------------|
| `GET /manifest?since={ts}&until={ts}` | Manifest of event IDs + timestamps |
| `GET /events?since={ts}` | Fetch encrypted events since timestamp |
| `GET /media/{hash}` | Fetch encrypted media blob by plaintext hash |
| `GET /status` | Relay info: pubkey, version, storage used/limit, event count |
| `POST /follow-request` | Submit a follow request for the owner to process |

### Owner-only (signature auth)

| Endpoint | Description |
|----------|-------------|
| `POST /events` | Push new encrypted events |
| `POST /media` | Push encrypted media blobs |
| `POST /follow-accept` | Forward encrypted feed key to a requester's endpoint |

### Authentication

Owner-only endpoints require:
```
X-Finch-Sig: base64(Ed25519.sign(owner_key, sha256(request_body)))
X-Finch-Pubkey: base64(owner_pubkey)
```

The relay verifies the pubkey matches its configured owner.

## Storage

### Backend
- **SQLite** for event metadata and indexing
- **Filesystem** for media blobs (hash-prefix sharded: `media/ab/cd/abcdef1234...`)
- All data is already encrypted by the client — the relay adds no encryption layer

### Schema (SQLite)

```sql
CREATE TABLE events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    pubkey      TEXT NOT NULL,
    created_at  INTEGER NOT NULL,
    nonce       BLOB NOT NULL,
    payload     BLOB NOT NULL
);
CREATE INDEX idx_events_created_at ON events(created_at);

CREATE TABLE media (
    hash        TEXT PRIMARY KEY,
    size        INTEGER NOT NULL,
    created_at  INTEGER NOT NULL,
    path        TEXT NOT NULL
);

CREATE TABLE follow_requests (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    requester_pubkey    TEXT NOT NULL,
    encrypted_endpoints BLOB NOT NULL,
    created_at          INTEGER NOT NULL,
    status              TEXT DEFAULT 'pending'
);
```

### Storage Limits
- Configurable max storage (default: 5GB)
- `/status` endpoint reports `storage_used` and `storage_limit`
- When limit reached: `POST /events` and `POST /media` return `507 Insufficient Storage`
- Oldest media can be pruned by the owner via the app

## Configuration (Standalone Server)

Single config file (`finch-relay.toml`):

```toml
# The owner's public key
owner_pubkey = "base32_encoded_pubkey"

# Server
listen_addr = "0.0.0.0"
listen_port = 8443

# TLS (optional -- not needed if using Tor-only)
tls_cert = "/etc/finch/cert.pem"
tls_key = "/etc/finch/key.pem"

# Tor (optional -- enable for .onion reachability)
tor_enabled = true

# Storage
data_dir = "/var/lib/finch"
max_storage_bytes = 5368709120  # 5GB

# Rate limiting
max_requests_per_minute = 120
```

## Deployment (Standalone Server)

### Docker
```dockerfile
FROM rust:alpine AS builder
WORKDIR /src
COPY . .
RUN cargo build --release

FROM alpine:latest
COPY --from=builder /src/target/release/finch-relay /usr/local/bin/
EXPOSE 8443
ENTRYPOINT ["finch-relay"]
```

### Fly.io
- `fly.toml` included in repo
- `fly launch` > picks region, provisions volume, deploys
- Persistent volume for `/var/lib/finch`

### Raspberry Pi
- Pre-built ARM64 binary
- systemd service file included
- Setup guide in docs

### Proxmox LXC
- Helper script: `scripts/proxmox-install.sh`
- Creates minimal Alpine LXC container
- Installs binary, generates TLS certs, creates systemd service
- Interactive prompts: owner pubkey, domain name, storage limit

## Standalone Binary Goals

- Target binary size: <10MB (static musl build)
- Memory usage: <50MB idle
- Handles 100+ concurrent readers on a $5/mo VPS
- SQLite handles write load fine — single owner, infrequent writes

## Security Considerations

- All data encrypted by client — relay compromise leaks only metadata
- Owner auth via Ed25519 prevents unauthorized writes
- Rate limiting prevents abuse
- TLS required for production over clearnet (not needed for Tor-only)
- Follow requests stored encrypted — only the owner's phone can decrypt them
