# Cyanea Roadmap

> From zero to federated "GitHub for Life Sciences"

---

## Philosophy

1. **Federation first** — Build the distributed architecture early, not as an afterthought
2. **Artifacts over files** — Typed, versioned scientific objects with lineage
3. **Prove the loop** — MVP must demonstrate: create → publish → discover → derive → credit
4. **Community is the moat** — Social mechanics and trust are as important as features
5. **Ship early, iterate fast** — Get feedback from real labs

---

## Phase 0: Foundation (Current)

**Goal:** Scaffolding and core infrastructure

### Completed

- [x] Project structure (Phoenix + Rust NIFs)
- [x] Docker Compose (Postgres, MinIO, Meilisearch)
- [x] Configuration (dev/test/prod)
- [x] Rust NIFs skeleton (FASTA, CSV, hash, compress)

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

## Phase 1: MVP (v0.1)

**Goal:** Prove federation + artifact lineage + community sharing

> "Install Cyanea Node in your lab. Keep internal work private. Publish the open parts to the Cyanea Network with one click. Others can fork, reproduce, and credit you."

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

## Phase 2: Federation (v0.2)

**Goal:** Full federation capabilities between nodes and hub

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

## Phase 3: Community (v0.3)

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

## Phase 4: Life Sciences Features (v0.4)

**Goal:** Domain-specific functionality for bioinformatics

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

## Phase 5: Reproducibility (v0.5)

**Goal:** Trust through reproducibility and QC

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

## Phase 6: Integrations (v0.6)

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

## Phase 7: Scale & Performance (v0.7)

**Goal:** Handle large datasets and many nodes

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

## Phase 8: Enterprise (v1.0)

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

## Phase 9: Intelligence (v1.x)

**Goal:** AI-powered research assistance

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

### Phase 1 (MVP)

| Metric | Target |
|--------|--------|
| Nodes installed | 10 |
| Registered users | 100 |
| Public artifacts | 200 |
| Active organizations | 20 |
| Derivations created | 50 |
| Page load time | <2s |

### Phase 2-3 (Federation + Community)

| Metric | Target |
|--------|--------|
| Federated nodes | 50 |
| Registered users | 1,000 |
| Public artifacts | 2,000 |
| Cross-node derivations | 100 |
| Discussions created | 500 |
| Daily active users | >10% |

### Phase 4-5 (Life Sciences + Repro)

| Metric | Target |
|--------|--------|
| Registered users | 5,000 |
| Artifacts with repro runs | 500 |
| Protocols forked | 200 |
| First DOI minted | Yes |
| QC pass rate | >80% |
| Scientific publication mention | Yes |

### Phase 6+ (Scale)

| Metric | Target |
|--------|--------|
| Registered users | 10,000+ |
| Federated nodes | 200+ |
| Enterprise pilots | 3 |
| Self-hosted deployments | 50 |
| CLI downloads | 1,000 |

---

## Non-Goals (Deliberate Exclusions)

Things we're explicitly NOT building (for now):

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

| Question | Phase | Considerations |
|----------|-------|----------------|
| Federation protocol | 1-2 | Custom, ActivityPub-inspired, OCI-like? |
| Artifact schema strictness | 1 | Permissive MVP vs strict validation? |
| Global ID format | 1 | `cyanea://org/project/artifact@version`? |
| Event sourcing depth | 1 | Full ES vs hybrid approach? |
| Manifest format | 1-2 | JSON, protobuf, custom? |
| Sync conflict resolution | 2 | Immutable = no conflicts, but metadata? |
| Key management | 2 | HSM, platform-managed, user-managed? |
| Search federation | 2 | Centralized index vs distributed query? |
| Compute for repro runs | 5 | Self-hosted only vs managed option? |

---

## Principles

1. **Federation is not optional** — Every feature should work in standalone and federated mode
2. **Artifacts have identity** — Content-addressed, globally referenceable, typed
3. **Lineage is sacred** — Never break the provenance chain
4. **Community > customers** — Researchers first, revenue second
5. **Open by default** — Make sharing easy, private when needed
6. **Design matters** — Scientists deserve beautiful tools
7. **Ship and iterate** — Perfect is the enemy of shipped
