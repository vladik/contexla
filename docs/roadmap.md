# Proof-driven roadmap

Contexla should grow through proofs. Each phase answers one important question
and leaves behind something usable.

## Current implementation status

As of 2026-11-23, the repository proves:

- the Phoenix/PostgreSQL platform boots against a repository-local database;
- the platform compiles, boots, and is tested with no concrete Application or
  Integration dependency;
- independently compiled Application and Integration BEAM paths are discovered
  and contract-validated through the runtime registry;
- registered external packages start as OTP Applications with their supervision
  trees, while package discovery remains free of migration side effects;
- Application manifests are checked against compiled definitions, owned
  migrations run explicitly, and Instance access enforces the pinned package
  version;
- Application Operations execute through a declared, schema-validated,
  Tool-aware and approval-aware boundary with auditable Invocation and
  optional Application Run linkage;
- independently compiled Applications access shared host facilities through
  explicit typed SDK Runtime functions rather than dynamic platform calls;
- current Instance and source-import lifecycle changes produce append-only,
  actor-attributed Audit Events, while Invocation data applies schema-based
  redaction and stores bounded failure codes;
- the platform builds as a package-neutral BEAM release with explicit release
  migration/bootstrap/diagnostic commands, public liveness/readiness probes,
  and documented coordinated backup/restore procedures;
- installation administrators have a bounded Operations Console and sanitized,
  checksummed support-bundle export backed by an isolated disclosure drill;
- Digital Estate Assessment owns its services, executor, workers, UI surfaces,
  reports, PostgreSQL schema, and migrations;
- an administrator can be bootstrapped without public registration or a shared
  default password;
- bootstrap credentials must be replaced before platform access;
- a validated, version-pinned Application Instance can be persisted;
- a Drupal snapshot ZIP can be security-checked, contract-validated, retained in
  content-addressed storage, and associated with an Instance as an immutable
  Artifact;
- bundled Tool packages are separately contract-validated;
- PostgreSQL mirrors immutable Tool versions, validates I/O, and records
  durable Tool Invocations before Oban execution;
- Oban durably queues Digital Estate Assessment Runs;
- the Drupal Adapter normalizes approved snapshot evidence into an immutable
  Snapshot, Inventory Items, and Relationships;
- the Application persists Evidence Items and deterministic Findings;
- authenticated LiveViews support creating an Assessment, uploading evidence,
  starting a Run, and inspecting the latest results;
- completed Runs expose a human-readable HTML report and machine-readable JSON
  report with scope, limitations, inventory, findings provenance, comparison,
  review history, and an evidence appendix;
- reviewers can add attributed expert findings and record append-only Finding
  disposition decisions with rationale;
- consecutive successful snapshots are compared deterministically, preserving
  added, changed, and removed inventory with before/after normalized values.
- a read-only Drush collector spike has produced clean and seeded snapshots from
  a disposable Drupal 11 site, and both completed the Artifact, native Composer
  Tool Invocation, Oban, persistence, comparison, Finding, and report path;
- aggregate content and media counts are retained as evidence-backed inventory.
- the authenticated shell exposes a persistent, context-aware Agent workspace
  with explicit no-AI behavior; Agent execution and persistence are not yet
  implemented;
- Content Integrity Monitor independently owns Monitors, Sources, Facts, Runs,
  Source Checks, Observations, Issues, Evidence, migrations, workers, and UI;
- its synthetic program-delivery proof acquires HTTP JSON/HTML, invokes exact
  JSON/HTML extraction Tools, applies delivery-delay policy, and preserves
  evidence and Issue history without AI.

The Application boundary and technical vertical slice work against controlled
fixtures and a synthetic Drupal installation. Source-linked development loading
is implemented; validated archive installation remains a later package-lifecycle
step. The synthetic Drupal proof does not validate the commercial outcome.
Digital Estate Assessment is now retained as an architecture proof rather than
the active commercial priority.

## Current proof sequence - Content Integrity Monitor

The current portfolio hypothesis and its business rationale are defined in
[business intent and current priorities](product/business-intent-and-priorities.md).

The native Composer proof has been migrated to the unified Tool model in
[Tool architecture and runtime](architecture/tool-runtime.md). This completed
refactor is not permission to build Python execution, dynamic package
installation, or a marketplace ahead of a real Application need.

### Proof A - Standalone product contract

**Question:** Is Content Integrity Monitor an independently useful Application
with a bounded, understandable first demonstration?

- define Monitor, Fact, Source, Observation, Comparison Policy, Issue,
  Evidence, and Run only to the depth required by the proof;
- define the user, inputs, outputs, first supported source types, and explicit
  exclusions;
- create a synthetic CMS/API/web/search or delivery scenario with deliberate
  missing, stale, and inconsistent facts;
- define the public demonstration, buyer questions, and stop condition before
  implementation expands.

**Status:** implemented in
[`content-integrity-monitor-v1.md`](product/content-integrity-monitor-v1.md).

### Proof B - Deterministic integrity vertical slice

**Question:** Can Contexla compare configured facts across authoritative and
delivered representations and preserve actionable evidence?

- acquire authoritative HTTP JSON;
- acquire configured HTTP JSON and HTML representations;
- extract and normalize a small set of typed values;
- compare healthy, pending, overdue, mismatch, missing, unavailable, and
  unknown states;
- persist Runs, Observations, Issues, and Evidence in the Application-owned
  domain;
- show open, acknowledged, and resolved Issues with bounded evidence and Tool
  provenance in a coherent Application UI.

**Status:** technically complete for the bounded synthetic proof. The Application-owned domain,
durable Runs, HTTP JSON/HTML acquisition, exact extraction Tools, deterministic
state model, Issues/Evidence persistence and lifecycle, evidence-oriented UI,
synthetic source service, and repeatable proof runner are implemented.
PostgreSQL-backed end-to-end validation completed on 2026-11-24 across
overdue, pending, and unavailable modes. Market validation remains open.

### Proof C - Portfolio validation

**Question:** Does the completed demonstration create useful buyer conversations
or related project opportunities?

- publish the working scenario rather than a hypothetical platform description;
- show it through the agency website, articles, LinkedIn, and direct outreach;
- test whether prospects can name critical facts, authoritative sources, and
  failing downstream representations;
- seek a bounded pilot, integration, deployment, or adjacent project;
- deepen, reposition, or stop based on response rather than adding speculative
  features.

### Proof D - Agent operation

**Question:** Can an agent configure and operate the deterministic integrity
workflow through declared Application Operations and stored evidence?

Manual UI/API operation remains first-class. The agent inspects available
Operations, Tools, and integration contracts, proposes mappings and
configuration, requests approval, starts Runs, monitors Activity, and explains
Findings without becoming the source of truth.

### Proof E - Agent extension

**Question:** Can an agent generate one reviewed Tool Package for a real
integrity operation without changing the platform or Application core?

Use the Tool manifest, package, validation, approval, version pinning, and
durable Invocation boundaries. Do not introduce Python or generated code merely
to demonstrate the runtime.

## Historical foundation sequence

The following proofs explain how the current foundation was built. They remain
architectural history, not the active commercial sequence.

## Proof 0 — Commercial problem

**Question:** Will an organization pay for a Digital Estate Assessment outcome?

- define the buyer, trigger, scope, evidence request, and deliverable;
- test it against recent Canadian Sitecore/Drupal opportunities;
- obtain a paid pilot or strong design partner commitment;
- manually perform work where software does not yet exist.
- test whether the assessment creates a credible path to planning,
  implementation, verification, support, or recurring assurance without making
  the initial deliverable dependent on follow-on sales.

**Exit evidence:** a real engagement shape and outputs that affect a customer's
decision.

## Proof 1 — Platform skeleton

**Question:** Can one independent OTP Application run on a small shared platform?

Build only the core, web shell, runtime conventions, and Digital Estate
Assessment Application boundary. Prove its own tables, workers, navigation,
authentication, Application Instances, and Oban execution.

## Proof 2 — Executable operation runtime

**Question:** Can Contexla execute small versioned operations reliably?

- one Capability/Processor proof (historical and superseded);
- one bundled Tool migration (implemented);
- one isolated Python Tool only for a real Application operation;
- manifest, structured input/output, permissions, timeout, result, durable
  Invocation history, and tests.

Avoid a sophisticated sandbox until this process-level proof works.

The native Tool migration is implemented. The isolated Python proof remains
deferred until a real operation justifies it.

## Proof 3 — Assessment vertical slice

**Question:** Can the product create a valuable assessment from real evidence?

- import a controlled Drupal estate snapshot;
- normalize inventory through a Client/Adapter boundary;
- persist an Application Instance and Run;
- generate several deterministic findings with linked evidence;
- render a useful report;
- support repeat execution and comparison.

All six bullets are implemented for controlled snapshots, including snapshots
collected from a synthetic Drupal 11 estate. Real-estate validation and
refinement against the buying decision remain open.

## Proof 4 — Agent-operated assessment

**Question:** Can an agent turn user intent into a safe, reviewable assessment
configuration?

The agent inspects the registry, explains missing access, proposes configuration,
starts an authorized Run, and summarizes evidence. Manual operation continues to
work unchanged.

## Proof 5 — Agent-created Tool

**Question:** Can an agent add a small operation without changing the platform?

Use a controlled development flow to generate, test, review, package, install,
approve, and pin one isolated Python Tool. Do not permit unrestricted production
installation or execution.

## Proof 6 — Live Drupal integration

**Question:** Does a repeatable read-only integration materially improve the
assessment?

Choose direct API, customer-run collector, or Drupal Connector based on evidence
from pilots. Add encrypted Connections and incremental acquisition only as
needed.

## Proof 7 — Reuse

**Question:** Is Contexla a platform rather than assessment-specific software?

Build Content Integrity Monitor as an independently useful package and reuse
proven execution, Artifacts, Operations, Tools, and UI conventions. Add
Connections only when the first supported acquisition path needs them.

## Later direction

Only after the current Content Integrity proofs should the portfolio or platform
expand toward additional Applications, broad vendor integration, Content
Transport, publishing gates, migration, syndication, or deeper autonomous
planning.

Runtime package marketplaces, arbitrary customer package combinations, and
self-service platform licensing are not roadmap goals until repeated customer
demand makes them necessary. Early distributions should contain a small,
supported set of packages for a purchased solution and must not become customer
forks.

