# Cyanea

> GitHub for Life Sciences. Open source. Beautiful. Fast.

Cyanea is an open source research data platform for life sciences. Store datasets, protocols, experiments, and analyses. Version control everything. Collaborate openly.

## Features

- **Spaces** — Organize datasets, notebooks, protocols, and results
- **Notebooks** — Interactive computational notebooks with WASM and server-side execution
- **Protocols** — Versioned, structured protocols with step tracking
- **Datasets** — Upload, preview, and version scientific data files
- **Organizations** — Labs, institutions, teams with role-based access
- **Federation** — Self-host a node, selectively publish to the network
- **Search** — Full-text search across all content
- **REST API** — JWT and API key auth, webhooks, full CRUD
- **ORCID** — Authenticate with your researcher identity

## Architecture

Cyanea is split into multiple repositories:

| Repo | Description |
|------|-------------|
| **[cyanea](https://github.com/cyanea-bio/cyanea)** | Phoenix web app — LiveView UI, API controllers, NIF bindings (this repo) |
| **[cyanea-core](https://github.com/cyanea-bio/cyanea-core)** | Shared Elixir library — schemas, contexts, workers |
| **[cyanea-hub](https://github.com/cyanea-bio/cyanea-hub)** | Private hub at app.cyanea.bio (also depends on cyanea-core) |
| **[labs](https://github.com/cyanea-bio/labs)** | Rust bioinformatics ecosystem (18 crates) |

Domain logic (Ecto schemas, context modules, Oban workers) lives in `cyanea-core` and is shared between the open-source node and the hub.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Elixir 1.17+ |
| Framework | Phoenix 1.8+ with LiveView |
| Domain Logic | [cyanea-core](https://github.com/cyanea-bio/cyanea-core) (shared library) |
| Database | SQLite via ecto_sqlite3 |
| Background Jobs | Oban (Lite engine) |
| File Storage | S3-compatible (AWS, MinIO, R2) |
| Search | Meilisearch |
| Performance | Rust NIFs via Rustler |
| Client Compute | WASM (cyanea-wasm) |

## Development

### Prerequisites

- Elixir 1.17+
- Rust (for NIFs)
- MinIO (local S3)
- Meilisearch

### Setup

```bash
# Clone side-by-side (NIFs reference labs/ via relative path)
git clone https://github.com/cyanea-bio/cyanea-core.git
git clone https://github.com/cyanea-bio/cyanea.git
git clone https://github.com/cyanea-bio/labs.git

# Start dependencies
cd cyanea
docker compose up -d

# Install dependencies and setup database
mix setup

# Start the server
mix phx.server
```

Now visit [`localhost:4000`](http://localhost:4000).

## Project Structure

```
cyanea/
├── lib/
│   ├── cyanea/              # App-specific modules
│   │   ├── application.ex   # OTP supervisor tree
│   │   ├── billing.ex       # Billing (permissive stub for open-source)
│   │   ├── native.ex        # Rust NIF bindings
│   │   ├── formats.ex       # File format detection (via NIFs)
│   │   └── *.ex             # Science modules (seq, align, chem, etc.)
│   └── cyanea_web/          # Phoenix web layer
│       ├── live/            # LiveView pages
│       ├── components/      # UI components
│       ├── controllers/     # REST API controllers
│       └── router.ex
├── native/
│   └── cyanea_native/       # Rust NIF crate
├── assets/                  # Frontend (Tailwind, JS, WASM)
├── priv/
│   ├── repo/migrations/     # Database migrations
│   └── static/              # Static assets
├── config/                  # Configuration
└── test/
    ├── cyanea/              # NIF module tests
    ├── cyanea_web/          # Web layer tests
    └── support/             # Fixtures, test helpers
```

Domain schemas, contexts, and workers are provided by `cyanea-core` (path dependency at `../cyanea-core`).

## License

MIT License - see [LICENSE.md](LICENSE.md)
