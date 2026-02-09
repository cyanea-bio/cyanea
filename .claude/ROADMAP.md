# Cyanea Roadmap

> From zero to the best Rust bioinformatics ecosystem + federated "GitHub for Life Sciences"

---

## Philosophy

1. **Foundations first** — Build world-class Rust libraries before/alongside the platform
2. **Federation first** — Build the distributed architecture early, not as an afterthought
3. **Artifacts over files** — Typed, versioned scientific objects with lineage
4. **Prove the loop** — MVP must demonstrate: create → publish → discover → derive → credit
5. **Community is the moat** — Social mechanics and trust are as important as features
6. **Ship early, iterate fast** — Get feedback from real users

---

## Two Tracks

Cyanea development runs on **two parallel tracks**:

```
                    2026                           2027                    2028
         Q1    Q2    Q3    Q4    Q1    Q2    Q3    Q4    Q1
         ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
LABS     │████████████████████████│     │     │     │     │  ← ALL COMPLETE (Q1 2026)
         │ 13 crates, 659+ tests │ GPU │     │     │     │  ← GPU backends pending HW
         ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
PLATFORM │ P0  │ P1  │ P2  │ P3  │ P4  │ P5  │ P6  │ P7  │  ← Elixir/Phoenix
         │found│ mvp │ fed │comm │life │repro│integ│scale│
         └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

**Labs status:** All 13 crates are fully implemented ahead of schedule. Remaining work is CUDA/Metal GPU backends (need hardware SDKs), SIMD vectorization (need profiling), and publishing to crates.io/npm/PyPI. Platform development can now consume Labs directly.

---

# LABS TRACK: Rust Bioinformatics Ecosystem

> Goal: Build the best open-source Rust libraries for life sciences by 2027

---

## Labs 0: Core Foundation (Q1 2026) — COMPLETE

**Goal:** Shared primitives and infrastructure

### cyanea-core

- [x] Workspace setup (Cargo workspace, 13 crates)
- [x] Common traits (`Sequence`, `ContentAddressable`, `Compressible`, `Summarizable`)
- [x] Error types with rich context (`thiserror` 2.x, `CyaneaError` enum)
- [x] Content addressing primitives (SHA-256)
- [x] Memory-mapped file utilities (std feature)
- [x] Compression support (zstd, gzip via flate2)
- [ ] Benchmarking infrastructure (criterion)
- [ ] Fuzzing setup (cargo-fuzz)

### cyanea-io

- [x] CSV parsing with metadata extraction
- [x] VCF variant parsing (vcf feature)
- [x] BED interval parsing (bed feature)
- [x] GFF3 hierarchical gene parsing (gff feature)
- [x] Feature-gated parsers for minimal dependency tree

---

## Labs 1: Sequences (Q2 2026) — COMPLETE

**Goal:** Best-in-class sequence handling

### cyanea-seq

- [x] **Parsers** — FASTA/FASTQ streaming via needletail
- [x] **Sequence types** — DNA, RNA, Protein with IUPAC alphabet validation
- [x] **Operations** — Reverse complement, translation (NCBI Table 1), k-mer iteration, GC content
- [x] **Quality** — Phred score handling (Phred33/64), mean quality, Q20/Q30 fractions
- [ ] **Indexing** — Suffix arrays, FM-index (deferred)
- [ ] **Compression** — 2-bit encoding (deferred)

### cyanea-py (Python bindings)

- [x] PyO3 bindings for sequence types (DnaSequence, RnaSequence, ProteinSequence)
- [x] FASTA/FASTQ parsing functions
- [x] Alignment, stats, core utils, ML distance submodules
- [x] maturin packaging

---

## Labs 2: Alignment (Q3 2026) — COMPLETE

**Goal:** Fast, accurate sequence alignment (CPU + GPU)

### cyanea-align

- [x] **Pairwise alignment** — Smith-Waterman (local), Needleman-Wunsch (global), semi-global; all with Gotoh 3-matrix affine gaps
- [x] **Scoring** — BLOSUM (45, 62, 80), PAM250, custom DNA/RNA matrices
- [x] **Banded alignment** — Banded NW, SW, and semi-global with configurable bandwidth; score-only mode
- [x] **MSA** — ClustalW-style progressive multiple sequence alignment
- [x] **Batch** — Batch pairwise alignment for all modes
- [x] **GPU dispatch** — GPU batch alignment with CPU fallback (CUDA/Metal backends gated)
- [x] **CIGAR** — Compact CIGAR string generation, identity/matches/gaps metrics
- [ ] **SIMD acceleration** — True vectorization deferred (scalar banded serves as baseline)
- [ ] **Heuristic alignment** — Seed-and-extend, minimizer seeding (deferred)

---

## Labs 3: Omics Data Structures (Q4 2026) — COMPLETE

**Goal:** Efficient data structures for omics data

### cyanea-omics

- [x] **Expression matrices** — Dense and COO sparse matrices with named rows/columns
- [x] **Genomic ranges** — GenomicPosition, GenomicInterval (0-based half-open), IntervalSet with overlap/merge/coverage
- [x] **Annotations** — Gene/Transcript/Exon hierarchy, GeneType classification
- [x] **Variants** — VCF-style Variant type, VariantType/Zygosity/Filter enums
- [x] **Single-cell** — AnnData-like container (obs, var, X, layers, obsm, varm, QC metrics)

### cyanea-io (format parsers)

- [x] CSV metadata extraction and preview
- [x] VCF variant parsing into cyanea-omics types
- [x] BED interval parsing (BED3-BED6)
- [x] GFF3 hierarchical gene parsing with coordinate conversion
- [ ] SAM/BAM/CRAM, Parquet, HDF5/Zarr (deferred)

---

## Labs 4: GPU Acceleration (Q1 2027) — PARTIAL (CPU Backend Complete)

**Goal:** First-class GPU support for compute-heavy operations

### cyanea-gpu

- [x] **Abstraction layer** — `Backend` trait (Send + Sync), `DeviceInfo`, `Buffer` type, `auto_backend()`
- [x] **CPU backend** — Full reference implementation (reductions, elementwise, matrix multiply, pairwise distances, batch z-score)
- [x] **Operations** — `reduce_sum/min/max/mean`, `elementwise_map`, `pairwise_distance_matrix`, `matrix_multiply`, `batch_pairwise`, `batch_z_score`
- [ ] **CUDA backend** — Feature-gated stub (requires CUDA SDK)
- [ ] **Metal backend** — Feature-gated stub (requires Metal SDK)

### cyanea-align (GPU dispatch)

- [x] `align_batch_gpu()` with `GpuBackend` enum (Auto/Cuda/Metal/Cpu)
- [x] CPU fallback always available
- [ ] Actual CUDA/Metal kernels (deferred, need hardware SDKs)

---

## Labs 5: WASM & Browser (Q2 2027) — COMPLETE (Bindings Ready)

**Goal:** Run bioinformatics in the browser

### cyanea-wasm

- [x] **JSON-based API** — All functions accept/return JSON strings for maximum JS interop
- [x] **wasm-bindgen** — All public functions annotated with `#[cfg_attr(feature = "wasm", wasm_bindgen)]`
- [x] **Sequence module** — FASTA/FASTQ parsing, GC content, reverse complement, transcribe, translate, validate
- [x] **Alignment module** — DNA/protein alignment (all modes), batch alignment, custom scoring
- [x] **Statistics module** — Descriptive stats, Pearson/Spearman, t-tests, Mann-Whitney, BH/Bonferroni correction
- [x] **ML module** — K-mer counting, Euclidean/Manhattan/Hamming/cosine distances
- [x] **Core utils** — SHA-256 hashing, zstd compress/decompress
- [ ] **npm packages** — Not yet published (@cyanea/*)
- [ ] **TypeScript type definitions** — Not yet generated
- [ ] **Web Worker integration** — Not yet built

---

## Labs 6: Statistics & ML (Q3 2027) — COMPLETE

**Goal:** Statistical methods and ML primitives for life sciences

### cyanea-stats

- [x] **Descriptive statistics** — mean, median, variance, std_dev, quantiles, IQR, MAD, skewness, kurtosis
- [x] **Correlation** — Pearson, Spearman, correlation matrices
- [x] **Hypothesis testing** — One-sample t-test, two-sample t-test (Student's/Welch's), Mann-Whitney U
- [x] **Distributions** — Normal, Poisson (pdf/cdf), erf, ln_gamma, regularized incomplete beta
- [x] **Multiple testing correction** — Bonferroni, Benjamini-Hochberg FDR
- [x] **Dimensionality reduction** — PCA (power iteration)
- [ ] ANOVA, Chi-square, Fisher's exact (not implemented)
- [ ] UMAP (not implemented)

### cyanea-ml

- [x] **Clustering** — K-means, DBSCAN, hierarchical (single/complete/average/Ward linkage)
- [x] **Distances** — Euclidean, Manhattan, cosine, Hamming; pairwise distance matrices
- [x] **Encoding** — One-hot and label encoding for DNA/RNA/protein
- [x] **Embeddings** — K-mer frequency embeddings, composition vectors, batch embedding, pairwise cosine distances
- [x] **Inference** — KNN (classify/regress), linear regression (normal equation)
- [x] **Dimensionality reduction** — PCA and t-SNE
- [x] **Evaluation** — Silhouette score/samples
- [x] **Normalization** — min-max, z-score, L2 (row-wise and column-wise)
- [ ] ONNX runtime integration (deferred)

---

## Labs: Domain Crates — COMPLETE

### cyanea-struct

- [x] PDB parsing (ATOM/HETATM/MODEL/ENDMDL)
- [x] Structure types (Point3D, Atom, Residue, Chain, Structure)
- [x] Geometry (distance, angle, dihedral, center of mass, RMSD)
- [x] Secondary structure assignment (simplified DSSP via phi/psi)
- [x] Structural superposition (Kabsch algorithm, CA alignment)
- [x] Contact maps (CA-only and all-atom)

### cyanea-chem

- [x] SMILES parsing (atoms, bonds, branches, rings, aromaticity, charges)
- [x] SDF/Mol V2000 parsing (single and multi-molecule)
- [x] Morgan/ECFP circular fingerprints, Tanimoto similarity
- [x] Molecular properties (weight, formula, HBD/HBA, rotatable bonds, logP)
- [x] Substructure search (VF2-style matching)
- [x] Ring detection (internal)

### cyanea-phylo

- [x] Tree types (PhyloTree, Node, pre-order/post-order iterators)
- [x] Newick I/O (parser + writer)
- [x] NEXUS I/O (parser + writer)
- [x] Evolutionary distances (p-distance, Jukes-Cantor, Kimura 2-parameter)
- [x] Tree comparison (Robinson-Foulds, branch score distance)
- [x] Tree construction (UPGMA, neighbor-joining)
- [x] Ancestral reconstruction (Fitch parsimony, Sankoff weighted parsimony, per-site)

---

# PLATFORM TRACK: Federated R&D Hub

> Goal: Build the federated "GitHub for Life Sciences"

---

## Platform 0: Foundation (Q1 2026)

**Goal:** Scaffolding and core infrastructure

### Completed

- [x] Project structure (Phoenix + Rust NIFs)
- [x] Docker Compose (Postgres, MinIO, Meilisearch)
- [x] Configuration (dev/test/prod)
- [x] Rust NIFs skeleton (wraps cyanea-* crates)

### In Progress

- [ ] Database migrations for new data model
  - [ ] Users, Organizations, Memberships
  - [ ] Projects (replacing Repositories)
  - [ ] Artifacts (typed: dataset, protocol, notebook, etc.)
  - [ ] ArtifactEvents (append-only event log)
  - [ ] Blobs (content-addressed storage)
  - [ ] FederationNodes
- [ ] Basic authentication (email/password)
- [ ] ORCID OAuth integration
- [ ] Guardian JWT setup
- [ ] S3 blob upload/download with content addressing
- [ ] Basic LiveView layouts

---

## Platform 1: MVP (v0.1) — Q2 2026

**Goal:** Prove federation + artifact lineage + community sharing

> "Install Cyanea Node in your lab. Keep internal work private. Publish the open parts to the Cyanea Network with one click. Others can fork, reproduce, and credit you."

**Depends on Labs:** cyanea-core, cyanea-seq (for file previews)

### Authentication & Identity

- [ ] Sign up with email/password
- [ ] Sign in with ORCID
- [ ] User profile page (name, bio, affiliation, ORCID link)
- [ ] Profile editing with avatar
- [ ] Password reset flow
- [ ] Email verification

### Organizations

- [ ] Create organization
- [ ] Organization profile page
- [ ] Invite members via email
- [ ] Member management (add/remove/change role)
- [ ] Roles: owner, admin, member, viewer
- [ ] Organization settings
- [ ] Verified badge (manual for MVP)

### Projects

- [ ] Create project (name, description, visibility, license)
- [ ] Project landing page ("card" view)
- [ ] Project settings (rename, transfer, delete)
- [ ] Visibility levels: private, internal, public
- [ ] License picker with common options
- [ ] Tags and ontology terms (free-form for MVP)

### Artifacts (Core Types)

- [ ] Create artifact (Dataset, Protocol, Notebook)
- [ ] Artifact card page (metadata, description, files)
- [ ] Artifact type-specific metadata schemas
- [ ] File browser within artifact
- [ ] Upload files to artifact (single and bulk)
- [ ] Download artifact (zip or individual files)
- [ ] Content-addressed blob storage (SHA256)

### Versioning & Lineage

- [ ] Immutable artifact versions (content hash)
- [ ] Version history view
- [ ] View artifact at specific version
- [ ] Create derivation ("fork" an artifact)
- [ ] Lineage graph visualization (parent → child)
- [ ] "Derived from" attribution on cards

### Basic Federation

- [ ] Global IDs for projects and artifacts (URI scheme)
- [ ] Node identity and configuration
- [ ] Publish artifact to hub (push)
- [ ] Publish project to hub (batch publish)
- [ ] Federation policy per project (none, selective, full)
- [ ] Basic manifest format for sync

### Discovery & Search

- [ ] Full-text search across projects/artifacts
- [ ] Search within project
- [ ] Filter by artifact type
- [ ] Filter by tags
- [ ] Search results with card previews

### Community (Basic)

- [ ] Star projects
- [ ] Watch projects (notifications placeholder)
- [ ] User activity feed
- [ ] Project activity feed

### UI/UX

- [ ] Responsive design (mobile-friendly)
- [ ] Dark/light theme
- [ ] Loading states and error handling
- [ ] Empty states with guidance
- [ ] Keyboard shortcuts (basic)

---

## Platform 2: Federation (v0.2) — Q3 2026

**Goal:** Full federation capabilities between nodes and hub

**Depends on Labs:** cyanea-core (content addressing, hashing)

### Sync Protocol

- [ ] Incremental sync (delta updates)
- [ ] Signed manifests (org/node keys)
- [ ] Conflict detection (immutable artifacts = no conflicts)
- [ ] Metadata merge strategies
- [ ] Sync status dashboard

### Hub Features

- [ ] Node registry (who's connected)
- [ ] Aggregate search across federated content
- [ ] Global artifact count/stats
- [ ] Hub admin dashboard

### Pull/Mirror

- [ ] Mirror public artifacts from hub to node
- [ ] Selective mirroring (by project, tag, org)
- [ ] Cache management for mirrored content
- [ ] Offline-first with sync on reconnect

### Cross-Node References

- [ ] Reference artifacts from other nodes (X@hash)
- [ ] Resolve cross-node lineage
- [ ] Display remote artifact cards (cached metadata)
- [ ] "View on origin" links

### Federation Policies

- [ ] Per-artifact publish rules
- [ ] Embargo dates (publish after X)
- [ ] Retraction workflow
- [ ] Access request for restricted content

---

## Platform 3: Community (v0.3) — Q4 2026

**Goal:** Social mechanics that make Cyanea feel alive

### Discussions & Annotations

- [ ] Discussions on projects
- [ ] Discussions on artifacts
- [ ] Comments on specific files/lines
- [ ] Mentions (@username)
- [ ] Markdown with preview

### Notifications

- [ ] In-app notification center
- [ ] Email notifications (configurable)
- [ ] Watch/unwatch granularity
- [ ] Digest mode (daily/weekly)

### Discovery Enhancements

- [ ] Trending projects
- [ ] Recently updated
- [ ] Featured/curated collections
- [ ] "Similar artifacts" recommendations
- [ ] Browse by organism, assay, modality

### Credits & Attribution

- [ ] Contributors list on artifacts
- [ ] Maintainer roles
- [ ] Citation generation (BibTeX, RIS)
- [ ] "Cite this" button
- [ ] Derived-from graph explorer

### Cards & Landing Pages

- [ ] Rich artifact cards (auto-generated from metadata)
- [ ] Custom card sections
- [ ] Badges (verified, reproducible, has DOI)
- [ ] Usage statistics on cards

### User Profiles

- [ ] Public profile pages
- [ ] Publication list (artifacts authored)
- [ ] Contribution graph
- [ ] Following users/orgs

---

## Platform 4: Life Sciences Features (v0.4) — Q1 2027

**Goal:** Domain-specific functionality for bioinformatics

**Depends on Labs:** cyanea-seq, cyanea-align, cyanea-omics, cyanea-io

### File Previews

- [ ] FASTA/FASTQ viewer with stats (via Rust NIF)
- [ ] CSV/TSV explorer (sort, filter, search)
- [ ] Image viewer (with zoom, pan, gallery)
- [ ] PDF viewer
- [ ] Jupyter notebook renderer
- [ ] Markdown with LaTeX support

### Protocol Editor

- [ ] Structured protocol format (YAML/JSON schema)
- [ ] Materials list with quantities
- [ ] Step-by-step procedures
- [ ] Timing and temperature annotations
- [ ] Equipment/instrument references
- [ ] Protocol versioning with diff
- [ ] Fork/adapt workflow

### Dataset Metadata

- [ ] Dataset card schema (inspired by HF)
- [ ] Column descriptions and types
- [ ] Data dictionary
- [ ] Sample/specimen relationships
- [ ] Quality metrics summary
- [ ] Known issues/caveats section

### Ontologies & Tagging

- [ ] Tag with Gene Ontology terms
- [ ] NCBI Taxonomy integration
- [ ] ChEBI (chemicals)
- [ ] EFO (experimental factors)
- [ ] Autocomplete from ontologies
- [ ] Ontology browser

### Sample Management

- [ ] Sample artifact type
- [ ] Sample metadata schema
- [ ] Sample → Dataset relationships
- [ ] Batch sample import (CSV)
- [ ] Sample lineage (derived samples)

---

## Platform 5: Reproducibility (v0.5) — Q2 2027

**Goal:** Trust through reproducibility and QC

**Depends on Labs:** cyanea-core (hashing), cyanea-stats (QC)

### Pipeline Integration

- [ ] Pipeline artifact type
- [ ] Nextflow wrapper support
- [ ] Snakemake wrapper support
- [ ] WDL/CWL support (basic)
- [ ] Container references (Docker/Singularity)
- [ ] Parameter schemas

### Run Records

- [ ] Record pipeline executions
- [ ] Capture: inputs, code hash, environment, outputs
- [ ] Link run → output artifacts
- [ ] Run comparison view
- [ ] "Reproduce this" button

### QC Gates

- [ ] Schema validation for artifacts
- [ ] Checksum verification on upload
- [ ] Basic stats checks (row count, null %, etc.)
- [ ] Custom validation rules (YAML config)
- [ ] QC badge on artifact cards

### Environment Capture

- [ ] Lockfile detection and storage
- [ ] Container image references
- [ ] Runtime environment snapshot
- [ ] Dependency graph visualization

### Attestations (Optional)

- [ ] Signed artifact manifests
- [ ] Org key management
- [ ] Verification UI
- [ ] Attestation history

### FAIR Compliance

- [ ] FAIR score calculator
- [ ] Metadata completeness check
- [ ] Persistent identifiers (DOI via DataCite)
- [ ] License clarity warnings
- [ ] FAIR improvement suggestions

---

## Platform 6: Integrations (v0.6) — Q3 2027

**Goal:** Connect to the research ecosystem

### API

- [ ] REST API v1
- [ ] GraphQL API (optional)
- [ ] API key management
- [ ] Rate limiting
- [ ] Webhooks (artifact events)
- [ ] OpenAPI documentation

### CLI

- [ ] `cyanea` CLI tool
- [ ] Login/auth flow
- [ ] Upload/download artifacts
- [ ] Clone projects
- [ ] Publish to hub
- [ ] Pull/mirror from hub
- [ ] Git-like UX where sensible

### External Services

- [ ] Zenodo sync (push datasets, get DOI)
- [ ] GenBank/UniProt linking
- [ ] PubMed paper linking
- [ ] ORCID profile sync
- [ ] GitHub import (repos → projects)

### Identity & Auth

- [ ] SAML SSO (enterprise)
- [ ] OIDC support
- [ ] Institutional login (InCommon, eduGAIN)

---

## Platform 7: Scale & Performance (v0.7) — Q4 2027

**Goal:** Handle large datasets and many nodes

**Depends on Labs:** cyanea-gpu (for compute), cyanea-wasm (for browser tools)

### Storage

- [ ] Chunked uploads for large files (>1GB)
- [ ] Resumable uploads
- [ ] Deduplication via content addressing
- [ ] Storage quotas per org
- [ ] Archive tier for cold artifacts
- [ ] Remote pointer support (don't store blob, just reference)

### Performance

- [ ] CDN for static assets and popular blobs
- [ ] Image/preview thumbnails
- [ ] Lazy loading for large artifact trees
- [ ] Pagination everywhere
- [ ] Background indexing
- [ ] Search result caching

### Infrastructure

- [ ] Kubernetes deployment (Helm chart)
- [ ] Horizontal scaling guide
- [ ] Database read replicas
- [ ] Redis for caching/sessions
- [ ] Prometheus metrics
- [ ] Grafana dashboards

### Federation Scale

- [ ] Efficient sync for large catalogs
- [ ] Partial sync (metadata only, blobs on demand)
- [ ] Sync scheduling and prioritization
- [ ] Federation health monitoring

---

## Platform 8: Enterprise (v1.0) — Q1 2028

**Goal:** Enterprise-ready, self-hosted platform

### Compliance

- [ ] Audit logs (all actions)
- [ ] Audit log export
- [ ] Retention policies
- [ ] Data deletion (GDPR)
- [ ] 21 CFR Part 11 (FDA) — future consideration

### Administration

- [ ] Admin dashboard
- [ ] User management
- [ ] Organization management
- [ ] Node configuration UI
- [ ] System health monitoring
- [ ] Backup/restore tools

### Security

- [ ] Two-factor authentication
- [ ] IP allowlisting
- [ ] Session management
- [ ] Security event logging
- [ ] Dependency vulnerability scanning

### Self-Hosted Excellence

- [ ] One-command Docker deploy
- [ ] Helm chart for Kubernetes
- [ ] Air-gapped installation support
- [ ] Upgrade path documentation
- [ ] Backup/restore guides
- [ ] Troubleshooting guide

### Sensitive Data

- [ ] PHI/PII detection warnings
- [ ] Export controls
- [ ] De-identification guidance docs
- [ ] Restricted visibility enforcement

---

## Platform 9: Intelligence (v1.x) — 2028+

**Goal:** AI-powered research assistance

**Depends on Labs:** cyanea-ml (embeddings, inference)

### Search & Discovery

- [ ] Semantic search (embeddings)
- [ ] Similar artifact recommendations
- [ ] Related protocol suggestions
- [ ] Cross-project linking suggestions

### AI Features

- [ ] Natural language queries
- [ ] Automatic metadata extraction
- [ ] Protocol summarization
- [ ] Data quality suggestions
- [ ] Anomaly detection in datasets

### Benchmarks & Challenges

- [ ] Challenge/benchmark scaffolding
- [ ] Leaderboards with reproducible runs
- [ ] Compute attestation
- [ ] Community benchmark curation

### Analytics

- [ ] Usage analytics dashboard
- [ ] Download/view statistics
- [ ] Citation tracking (if DOI)
- [ ] Impact metrics

---

## Future Ideas (Post-v1)

### Advanced Artifacts

- [ ] Model artifact type (bio ML models, HF-style)
- [ ] Registry items (plasmids, primers, antibodies)
- [ ] Instrument data integrations

### Interactive Apps

- [ ] "Spaces" — deploy visualizers/dashboards
- [ ] QC dashboard templates
- [ ] Data exploration apps
- [ ] Custom viewer plugins

### Collaboration

- [ ] Proposal/review workflow for artifact changes
- [ ] Suggested edits
- [ ] Merge requests for derived artifacts
- [ ] Real-time collaborative editing (stretch)

### Ecosystem

- [ ] Plugin/extension system
- [ ] Marketplace for templates
- [ ] Instrument integrations
- [ ] Lab notebook imports (ELN/LIMS)

---

## Milestones

### Cyanea Labs (Rust Ecosystem)

| Phase | Target | Status | Key Deliverable |
|-------|--------|--------|-----------------|
| L0 | Q1 2026 | **DONE** | cyanea-core: traits, errors, hashing, compression |
| L1 | Q1 2026 | **DONE** | cyanea-seq: sequences, FASTA/FASTQ, k-mers, quality |
| L2 | Q1 2026 | **DONE** | cyanea-align: NW, SW, semi-global, MSA, banded, GPU dispatch |
| L3 | Q1 2026 | **DONE** | cyanea-omics: matrices, intervals, variants, AnnData |
| L4 | Q1 2026 | **PARTIAL** | cyanea-gpu: CPU backend complete; CUDA/Metal need HW SDKs |
| L5 | Q1 2026 | **DONE** | cyanea-wasm: full bindings, wasm-bindgen ready |
| L6 | Q1 2026 | **DONE** | cyanea-stats + ml + chem + struct + phylo: all complete |
| — | Q1 2026 | **DONE** | cyanea-py: Python bindings (seq, align, stats, core, ml) |
| — | Q1 2026 | **DONE** | cyanea-io: CSV, VCF, BED, GFF3 parsers |

### Cyanea Platform (Federated Hub)

| Version | Target | Key Deliverable |
|---------|--------|-----------------|
| v0.1 | Q2 2026 | MVP: Artifacts, Projects, Basic Federation, Lineage |
| v0.2 | Q3 2026 | Federation: Full sync, mirroring, cross-node refs |
| v0.3 | Q4 2026 | Community: Discussions, notifications, discovery |
| v0.4 | Q1 2027 | Life Sciences: Protocols, datasets, ontologies |
| v0.5 | Q2 2027 | Reproducibility: Pipelines, runs, QC gates |
| v0.6 | Q3 2027 | Integrations: API, CLI, Zenodo, SSO |
| v0.7 | Q4 2027 | Scale: Large files, performance, infra |
| v1.0 | Q1 2028 | Enterprise: Compliance, admin, self-hosted |

---

## Success Metrics

### Cyanea Labs

| Phase | Metric | Target |
|-------|--------|--------|
| L1 | crates.io downloads (cyanea-seq) | 1K/month |
| L2 | GitHub stars (labs repo) | 500 |
| L3 | PyPI downloads (cyanea-py) | 5K/month |
| L5 | npm downloads (@cyanea/seq) | 2K/month |
| L6 | Academic citations | 5 papers |
| All | Benchmark performance | Fastest in class |
| All | WASM bundle size | <1MB core |
| All | Test coverage | >80% |

### Cyanea Platform

#### Platform 1 (MVP)

| Metric | Target |
|--------|--------|
| Nodes installed | 10 |
| Registered users | 100 |
| Public artifacts | 200 |
| Active organizations | 20 |
| Derivations created | 50 |
| Page load time | <2s |

#### Platform 2-3 (Federation + Community)

| Metric | Target |
|--------|--------|
| Federated nodes | 50 |
| Registered users | 1,000 |
| Public artifacts | 2,000 |
| Cross-node derivations | 100 |
| Discussions created | 500 |
| Daily active users | >10% |

#### Platform 4-5 (Life Sciences + Repro)

| Metric | Target |
|--------|--------|
| Registered users | 5,000 |
| Artifacts with repro runs | 500 |
| Protocols forked | 200 |
| First DOI minted | Yes |
| QC pass rate | >80% |
| Scientific publication mention | Yes |

#### Platform 6+ (Scale)

| Metric | Target |
|--------|--------|
| Registered users | 10,000+ |
| Federated nodes | 200+ |
| Enterprise pilots | 3 |
| Self-hosted deployments | 50 |
| CLI downloads | 1,000 |

---

## Non-Goals (Deliberate Exclusions)

### Cyanea Labs

| Non-Goal | Reason |
|----------|--------|
| Rewrite every tool | Focus on core primitives first |
| Support all GPU vendors day one | CUDA + Metal first, ROCm later |
| 100% parity with established tools | Focus on common cases, iterate |
| Build workflow orchestration | Provide building blocks, not engine |
| Windows GPU support (initial) | Focus on Linux/macOS first |

### Cyanea Platform

| Non-Goal | Reason |
|----------|--------|
| Mobile native apps | PWA is sufficient |
| Sequence editor | Use SnapGene, Benchling, etc. |
| Full LIMS replacement | Focus on sharing, not inventory |
| Workflow orchestration engine | Wrap existing (Nextflow, etc.) |
| Real-time collaborative editing | Too complex, defer |
| Perfect ontology coverage | Iterate based on usage |
| Central blob storage for everything | Support pointers/remote refs |
| Automated compliance | Provide tools, not magic |

---

## Open Design Questions

Decisions to make as we build (Claude Code should propose options):

### Cyanea Labs

| Question | Phase | Considerations |
|----------|-------|----------------|
| GPU abstraction strategy | L4 | Custom trait vs wgpu vs backend-specific |
| SIMD approach | L2 | std::simd (nightly) vs simdeez vs hand-written |
| WASM async model | L5 | Blocking + Workers vs async/await |
| Error handling crate | L0 | thiserror vs anyhow vs custom |
| Python binding style | L1+ | Thin bindings vs Pythonic wrappers |
| Workspace vs multi-repo | L0 | Single Cargo workspace vs separate repos |
| Minimum Rust version | L0 | Stable vs nightly (for SIMD, etc.) |
| Benchmarking datasets | L1+ | Synthetic vs real public datasets |

### Cyanea Platform

| Question | Phase | Considerations |
|----------|-------|----------------|
| Federation protocol | P1-2 | Custom, ActivityPub-inspired, OCI-like? |
| Artifact schema strictness | P1 | Permissive MVP vs strict validation? |
| Global ID format | P1 | `cyanea://org/project/artifact@version`? |
| Event sourcing depth | P1 | Full ES vs hybrid approach? |
| Manifest format | P1-2 | JSON, protobuf, custom? |
| Sync conflict resolution | P2 | Immutable = no conflicts, but metadata? |
| Key management | P2 | HSM, platform-managed, user-managed? |
| Search federation | P2 | Centralized index vs distributed query? |
| Compute for repro runs | P5 | Self-hosted only vs managed option? |

---

## Principles

### Cyanea Labs

1. **Performance is a feature** — If it's not fast, it won't be used
2. **WASM-first thinking** — Every library should work in the browser
3. **GPU is not optional** — Number-crunching needs acceleration
4. **Coherent APIs** — Consistent patterns across all crates
5. **Zero magic** — Transparent, documented algorithms
6. **Interop matters** — Python, JS, Elixir bindings are first-class
7. **Benchmark everything** — Claims require evidence

### Cyanea Platform

1. **Federation is not optional** — Every feature should work in standalone and federated mode
2. **Artifacts have identity** — Content-addressed, globally referenceable, typed
3. **Lineage is sacred** — Never break the provenance chain
4. **Community > customers** — Researchers first, revenue second
5. **Open by default** — Make sharing easy, private when needed
6. **Design matters** — Scientists deserve beautiful tools
7. **Ship and iterate** — Perfect is the enemy of shipped
