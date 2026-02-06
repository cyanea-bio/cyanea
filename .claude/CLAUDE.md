# Cyanea

> Federated, community-first life science R&D platform: "what GitHub/Hugging Face/Kaggle did for code & ML" applied to **bioinformatics, protocols, and experimental R&D artifacts**.

---

## Vision

### The Strategy: Foundation First

Cyanea is **two things**:

1. **Cyanea Labs** — A world-class Rust bioinformatics ecosystem (libraries, tools, standards)
2. **Cyanea Platform** — An **Elixir/Phoenix** federated R&D platform that consumes Labs

We build the **foundations first**. Before the platform ships, we create the best open-source Rust libraries for life sciences—coherent, fast, GPU-accelerated, and universally deployable (native + WASM). These libraries benefit everyone, establish Cyanea as a trusted name, and give our platform unmatched performance.

### How Labs + Platform Connect

The Platform is **Elixir/Phoenix**. Rust libraries are consumed in two ways:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Browser                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              WASM (cyanea-wasm)                            │  │
│  │   Sequence viewers, local parsing, client-side compute    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│               Cyanea Platform (Elixir/Phoenix)                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │   LiveView │ Channels │ REST API │ Oban Jobs │ Contexts   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │           NIFs via Rustler (cyanea_native)                 │  │
│  │   Heavy compute: parsing, alignment, hashing, compression │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Cyanea Labs (Rust)                          │
│    Standalone libraries — used by Platform, CLI, Python, etc.   │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐       │
│  │  cyanea-  │ │  cyanea-  │ │  cyanea-  │ │  cyanea-  │  ...  │
│  │    seq    │ │   align   │ │   omics   │ │    gpu    │       │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

| Integration | Mechanism | Use Case |
|-------------|-----------|----------|
| **Browser → Labs** | WASM (cyanea-wasm) | Client-side file preview, local parsing, interactive tools |
| **Platform → Labs** | NIFs (Rustler) | Server-side parsing, checksums, QC, heavy compute |
| **CLI → Labs** | Native Rust | Command-line tools, batch processing |
| **Python → Labs** | PyO3 | Data science workflows, Jupyter integration |

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
- Builders of foundational infrastructure (Rust libs) that everyone can use

### We Are Not (Initially)

- A full enterprise LIMS/ELN replacement for regulated workflows
- A lab inventory + ordering + compliance suite
- A single-vendor SaaS-only walled garden

---

## Cyanea Labs: Rust Bioinformatics Ecosystem

### Why Build This First?

The bioinformatics ecosystem is fragmented: Python wrappers around C code from the 90s, Java tools with GC pauses, R packages that don't scale. Modern life science computing deserves better.

**Our bet:** Re-implement the bioinformatics stack in Rust—coherent, fast, safe, and portable. Make it the foundation everyone builds on, including us.

| Problem | Cyanea Labs Solution |
|---------|---------------------|
| Fragmented tools, inconsistent APIs | Unified, coherent library design |
| Python/R too slow for large data | Native Rust performance |
| Can't run in browser | WASM compilation target |
| No GPU acceleration | First-class CUDA/Metal support |
| Hard to embed in other tools | Zero-dependency core, easy FFI |
| Poor error handling | Rust's type system + Result types |

### Design Principles

1. **Coherent API design** — Consistent patterns across all libraries
2. **Zero-copy where possible** — Memory-mapped files, streaming parsers
3. **WASM-first thinking** — Every library should compile to WASM (feature-gated GPU)
4. **GPU as first-class** — CUDA and Metal backends for compute-heavy operations
5. **Transparent internals** — Well-documented algorithms, no magic
6. **Extensible** — Traits and generics for customization
7. **Tested against real data** — Benchmarks on public datasets, not toy examples
8. **Interop-friendly** — C FFI, Python bindings (PyO3), Elixir NIFs

### Library Architecture

```
cyanea-labs/
├── cyanea-core/           # Shared primitives, traits, error types
├── cyanea-seq/            # Sequence I/O and manipulation
├── cyanea-align/          # Sequence alignment (local, global, MSA)
├── cyanea-omics/          # Omics data structures (matrices, annotations)
├── cyanea-stats/          # Statistical methods for life sciences
├── cyanea-ml/             # ML primitives for bio (embeddings, etc.)
├── cyanea-chem/           # Chemistry/small molecules
├── cyanea-struct/         # Protein/nucleic acid structures
├── cyanea-phylo/          # Phylogenetics and trees
├── cyanea-io/             # File format parsers (unified)
├── cyanea-gpu/            # GPU compute abstraction (CUDA/Metal)
├── cyanea-wasm/           # WASM bindings and browser runtime
└── cyanea-py/             # Python bindings (PyO3)
```

### Core Libraries

#### cyanea-core

Shared foundation for all libraries:

- Common traits (`Sequence`, `Annotation`, `Scored`, etc.)
- Error types with rich context
- Memory-mapped file utilities
- Streaming/iterator patterns
- Content addressing primitives (hashing)

#### cyanea-seq

Sequence handling—the heart of bioinformatics:

| Feature | Description |
|---------|-------------|
| **Parsers** | FASTA, FASTQ, GenBank, EMBL (streaming, zero-copy) |
| **Sequence types** | DNA, RNA, Protein, with alphabet validation |
| **Operations** | Reverse complement, translation, k-mers, motifs |
| **Quality** | Phred scores, trimming, filtering |
| **Indexing** | FM-index, suffix arrays for fast search |
| **Compression** | 2-bit encoding, reference-based compression |

#### cyanea-align

Sequence alignment with GPU acceleration:

| Feature | Description |
|---------|-------------|
| **Pairwise** | Smith-Waterman, Needleman-Wunsch (CPU + GPU) |
| **Scoring** | BLOSUM, PAM, custom matrices |
| **Heuristic** | Seed-and-extend, minimizers |
| **MSA** | Progressive alignment, profile HMMs |
| **GPU** | Batch alignment on CUDA/Metal for 100x speedup |

#### cyanea-omics

Data structures for omics data:

| Feature | Description |
|---------|-------------|
| **Expression matrices** | Dense/sparse, with sample/feature metadata |
| **Annotations** | Gene, transcript, protein annotations |
| **Variants** | VCF parsing, variant representation |
| **Single-cell** | AnnData-like structures, native Rust |
| **Genomic ranges** | Interval trees, BED/GFF/GTF parsing |

#### cyanea-io

Unified file format handling:

| Format | Type |
|--------|------|
| FASTA/FASTQ | Sequences |
| SAM/BAM/CRAM | Alignments |
| VCF/BCF | Variants |
| BED/GFF/GTF | Annotations |
| CSV/TSV/Parquet | Tabular |
| HDF5/Zarr | Arrays |
| PDB/mmCIF | Structures |
| SDF/MOL | Molecules |

#### cyanea-gpu

GPU compute abstraction:

```rust
// Unified API for CUDA and Metal
let gpu = GpuContext::new()?;  // Auto-detect backend
let result = gpu.batch_align(&sequences, &reference)?;
```

| Feature | Description |
|---------|-------------|
| **Backend abstraction** | Same API for CUDA and Metal |
| **Memory management** | Automatic host/device transfers |
| **Batch operations** | Optimized for throughput |
| **Fallback** | CPU fallback when no GPU available |

#### cyanea-wasm

Browser-ready bioinformatics:

- All pure-Rust libraries compile to WASM
- JavaScript/TypeScript bindings
- Web Workers for background processing
- Streaming for large files
- Powers Cyanea Platform's browser-based tools

### Performance Targets

| Operation | Target | Comparison |
|-----------|--------|------------|
| FASTQ parsing | 2 GB/s | 10x faster than BioPython |
| Smith-Waterman (CPU) | 10 GCUPS | Competitive with SIMD libs |
| Smith-Waterman (GPU) | 1 TCUPS | Batch alignment on RTX 4090 |
| k-mer counting | 500 M/s | Competitive with KMC |
| CSV parsing | 1 GB/s | Faster than pandas |

### WASM Considerations

Libraries are designed for WASM from the start:

- **Feature flags** — `#[cfg(feature = "wasm")]` for browser-specific code
- **No GPU in WASM** — GPU features gated behind `cuda`/`metal` features
- **Streaming I/O** — Works with browser File API
- **Small binaries** — Tree-shaking friendly, minimal dependencies
- **Async-ready** — Compatible with JavaScript async/await

### GPU Strategy

Support both major GPU platforms:

| Platform | Backend | Status |
|----------|---------|--------|
| NVIDIA | CUDA (via cudarc/rust-cuda) | Primary |
| Apple Silicon | Metal (via metal-rs) | Primary |
| AMD | ROCm | Future |
| WebGPU | wgpu | Future (enables GPU in browser) |

**When to use GPU:**

- Batch sequence alignment (>1000 sequences)
- Large matrix operations (single-cell, expression)
- ML inference (embeddings, predictions)
- Structure calculations (molecular dynamics)

### Language Bindings

Make libraries accessible everywhere:

| Language | Mechanism | Priority |
|----------|-----------|----------|
| **Rust** | Native | Primary |
| **Python** | PyO3 + maturin | High |
| **Elixir** | Rustler NIFs | High (platform) |
| **JavaScript** | WASM + wasm-bindgen | High |
| **C/C++** | cbindgen FFI | Medium |
| **R** | extendr | Medium |

### Relationship to Platform

The **Elixir/Phoenix platform** consumes Cyanea Labs via two paths:

#### Server-Side (NIFs via Rustler)

Heavy compute runs on the Elixir backend through Native Implemented Functions:

| Platform Feature | Cyanea Labs via NIFs |
|------------------|----------------------|
| File upload processing | cyanea-io (format detection, validation) |
| Content hashing | cyanea-core (SHA256, BLAKE3) |
| QC validation | cyanea-seq, cyanea-stats |
| Sequence indexing | cyanea-seq (k-mers, FM-index) |
| Alignment jobs | cyanea-align (batch alignment) |
| Compression | cyanea-core (zstd) |

#### Client-Side (WASM in Browser)

Interactive tools run directly in the browser without server round-trips:

| Platform Feature | Cyanea Labs via WASM |
|------------------|----------------------|
| FASTA/FASTQ viewer | cyanea-seq, cyanea-io |
| Sequence search | cyanea-seq (pattern matching) |
| Local file preview | cyanea-io (parse before upload) |
| Interactive alignment | cyanea-align (small sequences) |
| Client-side validation | cyanea-seq (format checks) |

#### Architecture Principle

> **Compute where it makes sense**: Use WASM for instant, interactive features (no latency). Use NIFs for heavy batch processing (server resources, GPU access).

### Success Metrics (Libraries)

| Metric | Target |
|--------|--------|
| **crates.io downloads** | 10K/month within 1 year |
| **GitHub stars** | 1K across ecosystem |
| **PyPI downloads** | 50K/month (Python bindings) |
| **npm downloads** | 10K/month (WASM bindings) |
| **Academic citations** | Mentioned in 10+ papers |
| **Performance** | Fastest in class for core operations |
| **WASM binary size** | <1MB for core functionality |

### Open Questions (Libraries)

| Question | Options |
|----------|---------|
| GPU abstraction | Custom vs wgpu vs backend-specific |
| WASM async model | Blocking vs async with Web Workers |
| Python binding style | Pythonic wrappers vs thin bindings |
| Monorepo vs multi-repo | Single repo vs separate crates |
| SIMD strategy | Portable SIMD vs architecture-specific |

---

## Tech Stack

### Cyanea Labs (Rust Libraries)

| Crate | Purpose | Targets |
|-------|---------|---------|
| **cyanea-core** | Shared primitives, traits, hashing | Native, WASM |
| **cyanea-seq** | Sequence I/O, manipulation, indexing | Native, WASM |
| **cyanea-align** | Pairwise and MSA alignment | Native, WASM, GPU |
| **cyanea-omics** | Expression matrices, variants, ranges | Native, WASM |
| **cyanea-io** | Unified file format parsing | Native, WASM |
| **cyanea-gpu** | CUDA/Metal compute abstraction | Native (GPU only) |
| **cyanea-wasm** | Browser runtime and JS bindings | WASM |
| **cyanea-py** | Python bindings via PyO3 | Python |

### Cyanea Platform (Elixir/Phoenix)

The platform is **100% Elixir/Phoenix**. Rust is only used for compute via NIFs and WASM.

| Layer | Technology | Why |
|-------|------------|-----|
| **Language** | Elixir 1.17+ | Concurrency, fault tolerance, LiveView |
| **Framework** | Phoenix 1.7+ | Real-time UI with LiveView |
| **Background Jobs** | Oban 2.18+ | Reliable, persistent, observable |
| **Database** | PostgreSQL 16 | JSONB, event sourcing friendly, proven |
| **File Storage** | S3-compatible | AWS S3, MinIO (self-hosted), R2 |
| **Search** | Meilisearch 1.11+ | Fast, typo-tolerant, self-hostable |
| **Server Compute** | Cyanea Labs via Rustler NIFs | Heavy parsing, alignment, hashing |
| **Client Compute** | Cyanea Labs via WASM | Browser-based tools, previews |
| **Auth** | ORCID OAuth + Guardian | Researcher identity + JWT |

### Why Rust for Libraries?

- **Performance** — Native speed, zero-cost abstractions
- **Safety** — Memory safety without GC, fearless concurrency
- **Portability** — Compile to native, WASM, embed anywhere
- **GPU** — First-class CUDA/Metal via Rust ecosystem
- **Ecosystem** — Growing bioinformatics community (rust-bio, noodles, etc.)
- **FFI** — Easy bindings to Python (PyO3), Elixir (Rustler), C, JS

### Why Elixir/Phoenix for Platform?

- **Real-time collaboration** — Phoenix Channels/LiveView built for WebSockets
- **Concurrent uploads** — BEAM handles thousands of connections
- **Fault tolerance** — Supervisors restart failed processes
- **Hot code reloading** — Deploy without dropping connections
- **Distribution-friendly** — Built for federated/distributed systems
- **Rust integration** — Rustler NIFs for compute-heavy operations

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
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Phoenix LiveView + Tailwind CSS                            ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  WASM Module (cyanea-wasm)                                  ││
│  │  └─ Client-side: file preview, sequence viewer, local parse ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│             Cyanea Platform (Elixir/Phoenix)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  LiveView   │  │  Channels   │  │     REST API            │  │
│  │  (UI)       │  │  (Realtime) │  │  (Integrations + Fed)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      Business Logic (Elixir)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Contexts   │  │    Oban     │  │   Cyanea.Native         │  │
│  │  (Domain)   │  │  (Jobs)     │  │   (NIF wrappers)        │  │
│  └─────────────┘  └─────────────┘  └───────────┬─────────────┘  │
│                                                 │                │
│                                                 ▼                │
│                                    ┌─────────────────────────┐  │
│                                    │  Rustler NIFs           │  │
│                                    │  └─ calls cyanea-* libs │  │
│                                    └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     Control Plane (Elixir)                       │
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

### Multi-Repo Layout

The project is split across **three separate git repositories** under the `cyanea-io` GitHub org, cloned side-by-side into a shared parent directory:

```
cyanea-io/                             # Parent directory (NOT a git repo)
├── labs/                              # Git repo: github.com/cyanea-io/labs
│   ├── Cargo.toml                     #   Rust Cargo workspace (13 crates)
│   ├── cyanea-core/                   #   Shared primitives, traits, errors
│   ├── cyanea-seq/                    #   Sequence I/O and manipulation
│   ├── cyanea-align/                  #   Sequence alignment (CPU + GPU)
│   ├── cyanea-omics/                  #   Omics data structures
│   ├── cyanea-stats/                  #   Statistical methods
│   ├── cyanea-io/                     #   File format parsers
│   ├── cyanea-ml/                     #   ML primitives for bio
│   ├── cyanea-chem/                   #   Chemistry / small molecules
│   ├── cyanea-struct/                 #   Protein/nucleic acid 3D structures
│   ├── cyanea-phylo/                  #   Phylogenetics and trees
│   ├── cyanea-gpu/                    #   GPU compute abstraction (CUDA/Metal)
│   ├── cyanea-wasm/                   #   WASM bindings + browser runtime
│   └── cyanea-py/                     #   Python bindings (PyO3)
├── cyanea/                            # Git repo: github.com/cyanea-io/cyanea
│   ├── lib/cyanea/                    #   Elixir business logic (contexts)
│   ├── lib/cyanea_web/                #   Phoenix web layer
│   ├── native/cyanea_native/          #   Rust NIF crate (depends on labs/ via path)
│   ├── config/                        #   Phoenix configuration
│   ├── priv/                          #   Migrations, static assets
│   ├── assets/                        #   Frontend (Tailwind, JS)
│   └── test/                          #   ExUnit tests
└── www/                               # Git repo: github.com/cyanea-io/www
    └── ...                            #   Marketing website (Zola)
```

**Important:** The NIF crate (`cyanea/native/cyanea_native/`) references labs crates via relative paths (e.g. `path = "../../../labs/cyanea-core"`), so `labs/` and `cyanea/` must be siblings in the same parent directory.

### Labs Structure (Rust)

```
labs/                                  # github.com/cyanea-io/labs
├── Cargo.toml                         # Workspace manifest (13 members)
├── cyanea-core/
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── error.rs                   # CyaneaError enum (thiserror 2.x)
│       ├── traits.rs                  # Sequence, ContentAddressable, Compressible
│       ├── hash.rs                    # SHA-256 content addressing
│       ├── compress.rs                # zstd + gzip (std feature only)
│       └── mmap.rs                    # Memory-mapped file access (std feature only)
├── cyanea-seq/
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── fasta.rs                   # FASTA/FASTQ parser (via needletail)
│       └── sequence.rs               # Sequence types (stub)
├── cyanea-io/
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs                     # CSV parsing (csv crate)
├── cyanea-align/                      # Stub — planned: SW, NW, MSA
├── cyanea-omics/                      # Stub — planned: expression matrices, VCF
├── cyanea-stats/                      # Stub — planned: descriptive stats, testing
├── cyanea-ml/                         # Stub — planned: embeddings, clustering
├── cyanea-chem/                       # Stub — planned: SMILES, molecular properties
├── cyanea-struct/                     # Stub — planned: PDB/mmCIF, RMSD
├── cyanea-phylo/                      # Stub — planned: Newick, tree distances
├── cyanea-gpu/                        # Stub — planned: CUDA/Metal abstraction
├── cyanea-wasm/                       # Stub — planned: wasm-bindgen browser bindings
└── cyanea-py/                         # Stub — planned: PyO3 Python bindings
```

Stub crates have `Cargo.toml` + `src/lib.rs` (doc comments only, no code yet). They compile and are part of the workspace but export nothing.

### Platform Structure (Elixir/Phoenix)

The platform is **pure Elixir/Phoenix**. Rust is only in `native/` as thin NIF wrappers.

```
cyanea/                                # github.com/cyanea-io/cyanea
├── lib/
│   ├── cyanea/                        # Business logic (Elixir contexts)
│   │   ├── accounts.ex                # Users, authentication
│   │   ├── accounts/                  # User schema, tokens
│   │   ├── organizations.ex           # Orgs context
│   │   ├── organizations/             # Organization, Membership schemas
│   │   ├── repositories.ex            # Repositories context
│   │   ├── repositories/              # Repository schema
│   │   ├── files/                     # Blob storage, content addressing
│   │   ├── search/                    # Meilisearch integration
│   │   ├── native.ex                  # Elixir NIF function stubs (Rustler)
│   │   ├── guardian.ex                # JWT auth
│   │   ├── application.ex             # OTP application
│   │   └── repo.ex                    # Ecto repo
│   └── cyanea_web/                    # Web layer (Phoenix)
│       ├── live/                      # LiveView pages
│       │   ├── home_live.ex
│       │   ├── dashboard_live.ex
│       │   ├── explore_live.ex
│       │   ├── settings_live.ex
│       │   ├── auth_live/             # Login, Register
│       │   ├── repository_live/       # New, Show
│       │   └── user_live/             # Show
│       ├── components/                # UI components (core_components, layouts)
│       ├── controllers/               # Session controller, error handlers
│       ├── router.ex
│       ├── endpoint.ex
│       ├── user_auth.ex               # Auth plugs and helpers
│       ├── telemetry.ex
│       └── gettext.ex
├── native/
│   └── cyanea_native/                 # Rust NIF crate (cdylib via Rustler)
│       ├── Cargo.toml                 # Depends on labs/ crates via path
│       ├── Cargo.lock
│       └── src/
│           └── lib.rs                 # #[rustler::nif] exports
├── priv/
│   ├── repo/migrations/               # Ecto database migrations
│   └── static/                        # Static assets
├── assets/                            # Frontend (Tailwind, JS)
├── config/                            # Phoenix configuration
└── test/                              # ExUnit tests
```

**Key principle:** All business logic lives in Elixir. NIFs are pure compute (parsing, hashing, alignment). No Rust in the hot path for web requests except when explicitly calling compute functions.

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

### Cyanea Labs (Rust Ecosystem)

| Area | Metric |
|------|--------|
| **Adoption** | crates.io downloads, PyPI downloads, npm downloads |
| **Performance** | Benchmarks vs alternatives (BioPython, SeqAn, etc.) |
| **Quality** | Test coverage, fuzzing coverage, zero CVEs |
| **Community** | GitHub stars, contributors, issues resolved |
| **Reach** | Academic citations, blog posts, conference talks |
| **Binaries** | WASM bundle size <1MB, native binary size |

### Cyanea Platform

| Area | Metric |
|------|--------|
| **Adoption** | Nodes installed, active monthly labs/users |
| **Sharing** | Published artifacts/month, forks/derivations, reproductions |
| **Trust** | % artifacts with reproducible runs, QC pass rates |
| **Community** | Discussions, citations, maintainer response times |
| **Federation** | Sync reliability, time-to-mirror, low friction publishing |

---

## Non-Goals (Deliberate Scope Limits)

### Cyanea Labs

- Rewrite every bioinformatics tool (focus on core primitives first)
- Support every GPU vendor from day one (CUDA + Metal first)
- Achieve 100% parity with established tools (focus on common use cases)
- Build a full workflow engine (provide building blocks instead)

### Cyanea Platform

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

### Cyanea Labs (Rust)

| Question | Options to Consider |
|----------|---------------------|
| GPU abstraction? | Custom trait vs wgpu vs backend-specific (cudarc/metal-rs) |
| SIMD strategy? | Portable SIMD (std::simd) vs architecture-specific (AVX2, NEON) |
| WASM async model? | Blocking + Web Workers vs async/await + wasm-bindgen-futures |
| Error handling? | thiserror vs anyhow vs custom error types |
| Repo structure? | Monorepo (Cargo workspace) vs separate repositories |
| Python binding style? | Pythonic wrappers vs thin bindings vs both |
| Build system for bindings? | maturin vs setuptools-rust for Python |
| Versioning? | Lockstep versions vs independent semver |

### Cyanea Platform

| Question | Options to Consider |
|----------|---------------------|
| Federation protocol? | Custom vs ActivityPub-ish vs OCI-like registries |
| Node architecture? | Mandatory core vs plugin-based |
| Storage approach? | Local blobs vs S3-compatible vs pointer-only |
| Identity model? | Platform accounts + org verification + key management |
| Schema enforcement? | Strict vs permissive in MVP |

---

## Related Repositories

| Repo | URL | Description |
|------|-----|-------------|
| **labs** | `github.com/cyanea-io/labs` | Rust bioinformatics ecosystem (Cargo workspace, 13 crates) |
| **cyanea** | `github.com/cyanea-io/cyanea` | Elixir/Phoenix platform (this repo) |
| **www** | `github.com/cyanea-io/www` | Marketing website (Zola) |

### Key Files in This Repo

- [ROADMAP.md](ROADMAP.md) — Development roadmap (Labs + Platform phases)
- [README.md](../README.md) — Project overview
- [docker-compose.yml](../docker-compose.yml) — Local development services
- `native/cyanea_native/` — Rust NIF crate (thin bridge to labs/)
