<p align="center">
  <a href="https://cyanea.bio">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/cyanea-bio/.github/main/brand/lockup-colour-dark.svg">
      <img alt="Cyanea" src="https://raw.githubusercontent.com/cyanea-bio/.github/main/brand/lockup-colour.svg" height="52">
    </picture>
  </a>
</p>

<h3 align="center">Cyanea Platform</h3>

<p align="center">The open-source, self-hostable Cyanea node: versioned, provenance-tracked notebooks, datasets and protocols that re-run.</p>

<p align="center">
  <a href="https://cyanea.bio">Website</a> &middot;
  <a href="https://docs.cyanea.bio">Docs</a> &middot;
  <a href="https://cyanea.bio/learn">Learn</a> &middot;
  <a href="https://github.com/cyanea-bio">All repositories</a>
</p>

---

## What this is

Cyanea is the system of record for computational biology. An analysis lives in a space with its data, notebooks and protocols; every change is a version, every result can be traced back through cells, code and datasets, and any version can be run again to get the same answer.

This repository is the Phoenix application that serves a Cyanea node: the LiveView interface, the REST API, notebook execution and the Rust NIF bridge. Run it next to your own data and share methods, not files. The hosted hub at [app.cyanea.bio](https://app.cyanea.bio) is built on the same core.

The computing is done by [Cyanea Labs](https://github.com/cyanea-bio/labs), the open-source Rust libraries, on the server through Rustler NIFs and in the browser through WebAssembly.

## Features

- **Spaces:** datasets, notebooks, protocols and results that version together
- **Notebooks:** interactive cells that run in the browser (WebAssembly) or on the server, with cell-level version diffs and restore
- **Provenance:** results linked to the cells, code versions and datasets that produced them
- **Protocols:** versioned, structured wet-lab and dry-lab protocols, with templates
- **Datasets:** upload, preview and version scientific files, with metadata extraction for 21 formats
- **Organisations:** labs and teams with owner, admin, member and viewer roles
- **Real-time collaboration:** presence and live cell updates
- **REST API:** JWT and API key auth, rate limiting, signed webhooks, Jupyter import
- **Federation:** self-host a node and publish selected work to the network
- **Search:** full-text search across spaces, datasets and protocols (Meilisearch)
- **ORCID:** sign in with your researcher identity

## Quickstart

Tool versions are pinned in `mise.toml` (Erlang 28, Elixir 1.19). Local services (MinIO for object storage, Meilisearch for search) run in Docker; the database is SQLite.

```bash
mise install                 # Erlang and Elixir
docker compose up -d         # MinIO and Meilisearch
mix setup                    # deps, database, seeds, assets
mix phx.server               # http://localhost:4000
```

The app depends on two sibling checkouts through relative paths:

```
cyanea-bio/
├── cyanea         # this repository
├── cyanea-core    # shared Elixir domain library (path dependency)
└── labs           # Rust crates used by the NIF (path dependency)
```

`cyanea-core` holds the schemas, contexts and workers shared with the hosted hub. It is not public yet, so a standalone build of this repository currently needs access to it.

Useful tasks (`mise run <task>`): `dev`, `test`, `lint`, `format`, `wasm` (build the Labs WebAssembly module and vendor it into the app).

## Structure

```
cyanea/
├── lib/
│   ├── cyanea/              # App modules: NIF bindings, format detection, science wrappers
│   └── cyanea_web/          # Phoenix web layer
│       ├── live/            # LiveView pages
│       ├── components/      # UI components and layouts
│       ├── controllers/     # REST API (v1)
│       └── router.ex
├── native/cyanea_native/    # Rust NIF crate (Rustler)
├── assets/                  # Tailwind, JS hooks, notebook worker, vendored WASM
├── priv/
│   ├── repo/migrations/     # Database migrations
│   └── static/              # Fonts, favicons, brand marks
├── config/
└── test/
```

## Tech stack

| Layer | Technology |
|---|---|
| Language | Elixir 1.17+ (1.19 pinned) |
| Web | Phoenix 1.8, LiveView |
| Domain | `cyanea-core` (Ecto schemas, contexts, Oban workers) |
| Database | SQLite (`ecto_sqlite3`); PostgreSQL supported by the core |
| Jobs | Oban |
| Storage | S3-compatible (AWS S3, MinIO, R2) |
| Search | Meilisearch |
| Compute | Rust via Rustler NIFs; WebAssembly in the browser |
| UI | Tailwind CSS with the Cyanea design tokens, Bricolage Grotesque, Inter, JetBrains Mono |

## Design

Colours, fonts and radii come from the Cyanea design tokens, compiled into `assets/tailwind-preset.cjs` and `assets/css/tokens.css`. Don't edit those two files by hand; they are generated from the shared design source.

## Licence

Apache License 2.0, the same as [Cyanea Labs](https://github.com/cyanea-bio/labs). See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Part of <a href="https://cyanea.bio">Cyanea</a>, the system of record for computational biology. Named for <i>Cyanea capillata</i>, the lion's mane jellyfish: long reach, lots of threads.</sub>
</p>
