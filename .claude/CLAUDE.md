# Cyanea

> Federated, community-first life science R&D platform: "what GitHub/Hugging Face/Kaggle did for code & ML" applied to **bioinformatics, protocols, and experimental R&D artifacts**.

---

## Vision

### The Problem

Benchling-style tools are great for *in-house* R&D, but fail at:

- **Public sharing** of research assets in a social + discoverable way
- **Fork/derive/credit** workflows for frictionless reuse and iteration
- **Federation**: orgs want local control + compliance, yet want to contribute openly
- **Post-AI reality**: AI makes generating analysis code easy; the scarce asset is **trusted data + provenance + reproducibility + collaboration norms**

### The Bet

In the post-AI economy, the platform moat is **curated, versioned, attributable scientific artifacts** + community dynamics—not proprietary notebooks.

### Brand Values

| Value | What It Means |
|-------|---------------|
| **Open** | Open source. Open data. Open science. Federated by design. |
| **Fast** | Instant search. Snappy UI. No loading spinners. |
| **Beautiful** | Design matters. Scientists deserve good tools. |
| **Trustworthy** | Provenance, reproducibility, and attribution are first-class. |
| **Community** | Give back. Share datasets. Help each other. |

### Name Origin

Cyanea (Greek "kyanos" = dark blue). Genus of jellyfish (lion's mane). The jellyfish metaphor: distributed nervous system = networked, federated research data.

---

## Core Concept: Platform Analogies

Cyanea borrows interaction primitives from code/ML platforms:

### GitHub-ish

| GitHub | Cyanea |
|--------|--------|
| Repos | **Projects** (collections of datasets, notebooks, protocols, results) |
| Commits | **Versioned artifact history** (immutable, content-addressed) |
| Issues/PRs | **Discussions + Proposals + Review** for dataset/protocol changes |
| Forks | **Derivations** (re-analyze, subset, transform; keep lineage) |
| Actions/CI | **Repro pipelines** (re-run, validate schema, QC checks) |
| Releases | **Citable snapshots** (DOI-friendly, signed, immutable) |

### Hugging Face-ish

| HF | Cyanea |
|----|--------|
| Model cards | **Dataset/Protocol/Experiment cards** (metadata, usage, caveats) |
| Spaces | **Interactive apps** (visualizers, QC dashboards, viewers) |
| Hub | **Registry** (searchable catalog, tags, organisms, assay types) |

### Kaggle-ish

| Kaggle | Cyanea |
|--------|--------|
| Competitions | **Challenges/Benchmarks** (community tasks on open datasets) |
| Notebooks | **Repro notebooks** with "run" and "compare" |
| Leaderboards | **Benchmark runs** (reproducible metrics, compute attestation) |

---

## Two-Layer Architecture

Cyanea is intentionally **hybrid**:

### A) Cyanea Node (Self-Hostable)

An installable node that organizations/labs run locally:

- Stores private and internal artifacts
- Supports notebook execution, pipeline runs, data registry, permissions
- Has "export lanes" to publish selected assets outward
- Can be **standalone** or **federated**

### B) Cyanea Network (Federation Hub)

The public/semi-public federation layer:

- Index, search, identity, community primitives
- Hosts open artifacts (or references) and collaboration surfaces
- Aggregates and mirrors content (when allowed)
- Provides discovery, reputation, and standardization

```
┌─────────────────────────────────────────────────────────────────┐
│                        Cyanea Network (Hub)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐│
│  │  Discovery   │  │   Identity   │  │      Federation         ││
│  │  + Search    │  │   + Orgs     │  │   Sync + Mirroring      ││
│  └──────────────┘  └──────────────┘  └─────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
           ▲                    ▲                    ▲
           │ push               │ push               │ pull
           │ publish            │ publish            │ mirror
┌──────────┴──────┐  ┌─────────┴───────┐  ┌────────┴────────────┐
│   Lab Node A    │  │   Lab Node B    │  │    Public Node      │
│   (Private)     │  │  (Federated)    │  │    (Open mirror)    │
└─────────────────┘  └─────────────────┘  └─────────────────────┘
```

---

## Federation Model (First-Class)

Federation is non-negotiable and practical:

- A node can be **standalone** (isolated) or **federated** (connected)
- Federation is **selective**: per-project/per-artifact publishing rules
- Support both:
  1. **Push publish**: local node pushes open artifacts + metadata to hub
  2. **Pull mirror**: node mirrors public artifacts from hub for local compute/caching
- Enable **cross-node references**: "this derived dataset comes from X@hash"

### Minimum Federation Primitives

| Primitive | Purpose |
|-----------|---------|
| **Global IDs** | Stable resource identifiers (URI-like) |
| **Content addressing** | Hashes for immutable blobs |
| **Signed manifests** | Attest who published what (org keys; optional) |
| **Sync protocol** | Incremental sync, conflict rules, access rules |

---

## Scientific Artifacts (Domain Objects)

Cyanea is not "just files"—it's **typed, versioned scientific artifacts**:

| Artifact Type | Description |
|---------------|-------------|
| **Dataset** | Tabular, sequences, images, omics matrices |
| **Sample** | Biospecimen metadata (structured, schema'd) |
| **Protocol / SOP** | Steps, reagents, instruments, parameters; versioned |
| **Notebook / Analysis** | Jupyter-like, artifact-native; runnable, comparable |
| **Pipeline / Workflow** | Nextflow/Snakemake/WDL/CWL wrappers; containerized |
| **Results** | Figures, tables, metrics, reports |
| **Registry Items** | Plasmids, primers, antibodies, constructs (future) |
| **Model** | Bio ML models (aligns with HF analogy; future) |

### Every Artifact Has

- **Metadata card** — what it is, how created, limitations, license
- **Lineage graph** — inputs → transforms → outputs
- **Permissions** — private / internal / public
- **Repro info** — environment, parameters, tool versions

---

## Trust, Provenance, Reproducibility (The Moat)

If AI can generate analysis, Cyanea must guarantee *believability*:

| Feature | Purpose |
|---------|---------|
| Immutable snapshots + checksums | Tamper-proof records |
| Dependency capture | Containers, lockfiles for runs |
| Run records | Inputs, code hash, environment, outputs |
| QC gates | Schema validation, checksum verification, stats checks |
| Signed attestations | Lab/institution keys (optional) |
| Clear licensing | Defaults + warnings on "no license" |

---

## Openness Levels

Multiple visibility modes to match real-world needs:

| Level | Description |
|-------|-------------|
| **Fully public** | Open to all, discoverable on network |
| **Public metadata + restricted blobs** | Pointer-based, request access |
| **Consortium-only** | Shared among specific orgs |
| **Private / local** | Never leaves the node |

### Sensitive Data Guardrails

- Strong red flags for human subject data, PHI
- Export controls and audit logs
- De-identification guidance (but don't pretend to solve it magically)

---

## Community Features (Social Mechanics)

Cyanea must feel like a community platform, not a sterile LIMS:

- User/org profiles + verification (labs, institutions)
- Search with rich tags (organism, assay, modality, tissue, disease, instrument)
- Stars / watch / subscriptions
- Discussions and annotations on artifacts
- Citations + credits (contributors, maintainers, derived-from graph)
- "Cards" as canonical landing pages
- Challenge/benchmark scaffolding (network effects)

---

## What We Are vs Aren't

### We Are

- Community-first, federated, artifact-native, reproducibility-obsessed
- The open alternative that respects data ownership

### We Are Not (Initially)

- A full enterprise LIMS/ELN replacement for regulated workflows
- A lab inventory + ordering + compliance suite
- A single-vendor SaaS-only walled garden

---

## Tech Stack

| Layer | Technology | Why |
|-------|------------|-----|
| **Language** | Elixir 1.17+ | Concurrency, fault tolerance, LiveView |
| **Framework** | Phoenix 1.7+ | Real-time UI with LiveView |
| **Background Jobs** | Oban 2.18+ | Reliable, persistent, observable |
| **Database** | PostgreSQL 16 | JSONB, event sourcing friendly, proven |
| **File Storage** | S3-compatible | AWS S3, MinIO (self-hosted), R2 |
| **Search** | Meilisearch 1.11+ | Fast, typo-tolerant, self-hostable |
| **Performance** | Rust NIFs | FASTA parsing, checksums, compression |
| **Auth** | ORCID OAuth + Guardian | Researcher identity + JWT |

### Why Elixir/Phoenix?

- **Real-time collaboration** — Phoenix Channels/LiveView built for WebSockets
- **Concurrent uploads** — BEAM handles thousands of connections
- **Fault tolerance** — Supervisors restart failed processes
- **Hot code reloading** — Deploy without dropping connections
- **Distribution-friendly** — Built for federated/distributed systems

### Why Rust NIFs?

- **FASTA/FASTQ parsing** — GB-sized sequence files need native speed
- **CSV processing** — Large datasets, streaming parse
- **Checksums** — SHA256 for content addressing
- **Compression** — zstd for storage efficiency

---

## Architecture Principles

### Event-Sourced Core

Prefer append-only history for artifacts + lineage:

- Immutable artifact versions (avoid conflicts in federation)
- Mutable metadata via event log + projections
- Full provenance trail built-in

### Control Plane vs Data Plane

| Plane | Responsibility |
|-------|----------------|
| **Control** | Metadata, identities, lineage, permissions, search |
| **Data** | Blob storage (S3/MinIO/local); supports remote pointers |

### Federation Design

- Syncable manifests + incremental updates
- Conflict resolution: immutable artifacts avoid conflicts; metadata merges
- Content addressing for blobs, stable IDs for resources

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser                                   │
│              Phoenix LiveView + Tailwind CSS                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phoenix Application                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  LiveView   │  │  Channels   │  │     REST API            │  │
│  │  (UI)       │  │  (Realtime) │  │  (Integrations + Fed)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      Business Logic                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Contexts   │  │    Oban     │  │    Rust NIFs            │  │
│  │  (Domain)   │  │  (Jobs)     │  │  (Performance)          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     Control Plane                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Artifacts  │  │  Lineage    │  │    Federation           │  │
│  │  + Events   │  │  Graph      │  │    Sync Engine          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                       Data Plane                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Postgres   │  │    S3       │  │    Meilisearch          │  │
│  │  (Metadata) │  │  (Blobs)    │  │    (Search)             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
cyanea/
├── lib/
│   ├── cyanea/                    # Business logic (contexts)
│   │   ├── accounts/              # Users, authentication, ORCID
│   │   ├── organizations/         # Orgs, teams, memberships
│   │   ├── projects/              # Projects (artifact collections)
│   │   ├── artifacts/             # Typed artifacts (datasets, protocols, etc.)
│   │   ├── lineage/               # Provenance graph, derivations
│   │   ├── federation/            # Sync engine, manifests, node registry
│   │   ├── files/                 # Blob storage, content addressing
│   │   ├── search/                # Meilisearch integration
│   │   ├── application.ex         # OTP application
│   │   ├── repo.ex                # Ecto repo
│   │   └── native.ex              # Rust NIF bindings
│   └── cyanea_web/                # Web layer
│       ├── live/                  # LiveView pages
│       ├── components/            # UI components
│       ├── controllers/           # API controllers
│       ├── endpoint.ex
│       └── router.ex
├── native/
│   └── cyanea_native/             # Rust NIFs
│       └── src/
│           ├── lib.rs             # NIF exports
│           ├── fasta.rs           # FASTA/FASTQ parsing
│           ├── csv_parser.rs      # CSV streaming
│           ├── hash.rs            # SHA256 checksums
│           └── compress.rs        # zstd compression
├── priv/
│   ├── repo/migrations/           # Database migrations
│   └── static/                    # Static assets
├── assets/                        # Frontend assets (Tailwind, JS)
├── config/                        # Configuration
└── test/                          # Tests
```

---

## Data Model

### Core Entities

```
User
├── id (UUID)
├── email, username, name
├── orcid_id
├── password_hash
├── affiliation, bio, avatar_url
├── public_key (optional, for signing)
└── timestamps

Organization
├── id (UUID)
├── name, slug (unique)
├── description
├── verified (institution verification)
├── public_key (optional, for signing)
└── timestamps

Membership
├── user_id → User
├── organization_id → Organization
├── role (owner | admin | member | viewer)
└── timestamps

Project
├── id (UUID)
├── global_id (federation URI)
├── name, slug
├── description
├── visibility (public | internal | private)
├── license
├── owner_id → User (nullable)
├── organization_id → Organization (nullable)
├── tags [], ontology_terms []
├── federation_policy (none | selective | full)
└── timestamps

Artifact
├── id (UUID)
├── global_id (federation URI)
├── type (dataset | protocol | notebook | pipeline | result | sample)
├── name, slug
├── version (semantic or hash-based)
├── content_hash (SHA256, immutable)
├── metadata (JSONB - type-specific card data)
├── project_id → Project
├── parent_artifact_id → Artifact (for derivations)
├── author_id → User
├── visibility
└── timestamps

ArtifactEvent (append-only)
├── id (UUID)
├── artifact_id → Artifact
├── event_type (created | updated | derived | published | etc.)
├── payload (JSONB)
├── actor_id → User
└── timestamp

Blob
├── id (UUID)
├── sha256 (content hash, unique)
├── size
├── mime_type
├── storage_key (S3 key or remote pointer)
├── storage_type (local | s3 | remote_pointer)
└── timestamps

ArtifactBlob (join table)
├── artifact_id → Artifact
├── blob_id → Blob
├── path (file path within artifact)
└── timestamps

FederationNode
├── id (UUID)
├── name, url
├── public_key
├── last_sync_at
├── status (active | inactive)
└── timestamps
```

---

## MVP Scope

**Goal:** Prove federation + artifact lineage + community sharing.

### MVP Capabilities

1. **Projects + artifact registry** — Dataset, Analysis/Notebook, Protocol
2. **Versioning + lineage graph** — Derive/fork, track provenance
3. **Publish workflow** — Node → Hub selective export
4. **Hub discovery** — Search, tags, cards, stars, discussions
5. **Repro runs** — Basic pipeline execution records
6. **Permissions model** — Private / internal / public + orgs/teams

### MVP Narrative

> "Install Cyanea Node in your lab. Keep internal work private. Publish the open parts to the Cyanea Network with one click. Others can fork, reproduce, and credit you—like GitHub, but for R&D artifacts."

---

## Development

### Prerequisites

- Elixir 1.17+
- PostgreSQL 16+
- Rust (for NIFs)
- Docker (for MinIO/Meilisearch)

### Setup

```bash
# Start dependencies
docker compose up -d

# Install Elixir deps
mix deps.get

# Setup database
mix ecto.setup

# Start server
mix phx.server
```

### Useful Commands

```bash
mix test                 # Run tests
mix format               # Format code
mix credo --strict       # Check code quality
mix dialyzer             # Type checking
mix ecto.gen.migration   # Generate migration

# Rust NIFs
cd native/cyanea_native && cargo build --release
```

---

## Conventions

### Code Style

- Follow standard Elixir formatting (`mix format`)
- Use contexts for business logic (not in LiveViews)
- Keep LiveViews thin—delegate to contexts
- Use `with` for happy-path chaining
- Prefer pattern matching over conditionals

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Contexts | Singular | `Artifacts`, `Projects` |
| Schemas | Singular | `Artifact`, `Project` |
| Tables | Plural | `artifacts`, `projects` |
| LiveViews | `*Live` suffix | `ProjectLive` |
| Components | `*Component` or `CoreComponents` | `CardComponent` |

### Testing

- Unit tests for contexts
- Integration tests for LiveViews
- Use `Cyanea.DataCase` for database tests
- Use `CyaneaWeb.ConnCase` for web tests

---

## Oban Job Queues

| Queue | Purpose | Concurrency |
|-------|---------|-------------|
| `default` | Notifications, webhooks | 10 |
| `uploads` | File processing, checksums, content addressing | 5 |
| `analysis` | Sequence analysis, validation, QC | 3 |
| `federation` | Sync, publish, mirror operations | 5 |
| `exports` | Dataset exports, DOI minting | 2 |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Phoenix secret (64+ bytes) |
| `PHX_HOST` | Public hostname |
| `AWS_ACCESS_KEY_ID` | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key |
| `S3_BUCKET` | S3 bucket name |
| `MEILISEARCH_URL` | Meilisearch endpoint |
| `MEILISEARCH_API_KEY` | Meilisearch API key |
| `ORCID_CLIENT_ID` | ORCID OAuth client ID |
| `ORCID_CLIENT_SECRET` | ORCID OAuth secret |
| `FEDERATION_NODE_URL` | This node's public URL (if federated) |
| `FEDERATION_HUB_URL` | Hub URL to federate with |
| `NODE_SIGNING_KEY` | Private key for signing manifests |

---

## Success Metrics

| Area | Metric |
|------|--------|
| **Adoption** | Nodes installed, active monthly labs/users |
| **Sharing** | Published artifacts/month, forks/derivations, reproductions |
| **Trust** | % artifacts with reproducible runs, QC pass rates |
| **Community** | Discussions, citations, maintainer response times |
| **Federation** | Sync reliability, time-to-mirror, low friction publishing |

---

## Non-Goals (Deliberate Scope Limits)

- Perfectly model "all of biology" in one ontology from day one
- Replace every existing workflow engine (integrate + wrap instead)
- Store every large blob centrally (support pointers/remote stores)
- Solve human-subject compliance automatically (provide tooling + constraints)
- Mobile native apps (PWA is enough)
- Real-time collaborative editing (complex, defer)
- Full LIMS/ELN for regulated workflows (later)

---

## Open Questions (Design Levers)

These are areas where Claude Code should propose options, not assume:

| Question | Options to Consider |
|----------|---------------------|
| Federation protocol? | Custom vs ActivityPub-ish vs OCI-like registries |
| Node architecture? | Mandatory core vs plugin-based |
| Storage approach? | Local blobs vs S3-compatible vs pointer-only |
| Identity model? | Platform accounts + org verification + key management |
| Schema enforcement? | Strict vs permissive in MVP |

---

## Related Files

- [ROADMAP.md](ROADMAP.md) — Development roadmap with phases
- [README.md](../README.md) — Project overview
- [docker-compose.yml](../docker-compose.yml) — Local development services
