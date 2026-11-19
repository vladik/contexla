# Assessment domain model

This is the proposed domain for the first vertical slice. Names can change
during implementation, but the ownership and evidence boundaries should remain.

## Ownership

Digital Estate Assessment owns assessment scope, normalized inventory,
relationships, findings, review decisions, and report projections.

The platform may later own shared Application Instance, Run, Connection, and
Artifact primitives. The first proof should not force Assessment data into
generic records before a second Application demonstrates reuse.

## Main entities

### Assessment

One configured assessment engagement or recurring assessment context. It is the
first form of an Application Instance.

Key attributes:

- name and status;
- decision being supported;
- scope and exclusions;
- customer-facing dates;
- policy/configuration version;
- owner and reviewers.

For the first bundled slice, the platform `application_instances` row is the
Assessment record. Decision and scope live in its validated configuration. A
second `assessments` or `assessment_instances` table is deliberately avoided.

### Target

A system or bounded estate included in an Assessment, such as one Drupal
installation. A Target is not a Connection: it describes what is being
assessed, while a Connection describes how Contexla can access something.

Key attributes:

- source type and stable external identity;
- name and description;
- environment/estate boundaries;
- owner when known;
- Connection binding when live access exists.

### Assessment Run

One immutable execution context for collecting or importing evidence,
normalizing a snapshot, evaluating rules, and producing draft findings.

Key attributes:

- status and timestamps;
- trigger and initiating user;
- Target set;
- Adapter and rule-set versions;
- input package identities;
- execution summary and failure details.

Repeating an assessment creates a new Run; it does not overwrite the prior Run.

### Evidence Package

One acquired, immutable package and its validated manifest. Store the original
package or an immutable artifact reference plus its hash.

### Evidence Item

A file, record set, interview note, diagram, or external reference supporting
inventory or findings.

Key attributes:

- package-relative identity or artifact reference;
- media type, hash, size, and collection time;
- source and collection method;
- sensitivity classification;
- validation state and provenance.

### Snapshot

The normalized view of a Target derived by a specific Adapter version from a
specific set of Evidence Items. A Snapshot is immutable after a Run completes.

### Snapshot Comparison

An immutable deterministic comparison between consecutive successful Snapshots
for the same Application Instance and target. Inventory is matched by kind and
stable external key, then classified as added, removed, or changed. It records
the exact before/after normalized values rather than an AI interpretation.

### Inventory Item

A typed item within a Snapshot. Initial types include installation,
environment, site, module, content type, field, theme/component, integration,
infrastructure service, and code package.

Key attributes:

- type and source-native identity;
- normalized identity within the Target;
- name and selected typed attributes;
- lifecycle/ownership metadata;
- provenance references;
- completeness and confidence.

Do not put all source data into one unbounded JSON object. A JSON attributes
field may preserve source-specific metadata, but frequently queried domain
properties deserve explicit fields or typed projections.

### Relationship

A directed, typed edge between Inventory Items, for example:

```text
site -> runs_on -> installation
site -> uses -> module
integration -> sends_to -> external_system
content_type -> contains -> field
code_package -> implements -> integration
```

Every Relationship records provenance and may be declared, observed, or
inferred. Inferred relationships must record the rule or reviewer responsible.

### Finding

An Assessment-domain conclusion produced by a deterministic rule or entered by
an expert.

Key attributes:

- stable rule identifier and rule version, when applicable;
- category, title, observation, and affected scope;
- decision impact and confidence;
- evidence references;
- recommendation and disposition;
- origin: deterministic rule or named expert;
- review status and review history.

An AI explanation may be attached, but it is not the Finding's authoritative
observation or evidence.

### Review Decision

An append-only record of a reviewer action on a Finding or normalized value,
including actor, time, previous/new state, and rationale.

## High-level relationships

```text
Assessment
  -> has many Targets
  -> has many Assessment Runs

Assessment Run
  -> uses Targets
  -> consumes Evidence Packages
  -> produces Snapshots
  -> produces Findings

Evidence Package
  -> contains Evidence Items

Snapshot
  -> contains Inventory Items
  -> contains Relationships
  -> compared with prior Snapshot by a Snapshot Comparison

Finding
  -> affects Targets or Inventory Items
  -> supported by Evidence Items
  -> has Review Decisions
```

## Evidence invariants

- Original Evidence Items are never silently modified.
- Every normalized item can identify its source evidence and Adapter version.
- Every deterministic Finding records its rule and version.
- Expert and deterministic Findings remain distinguishable.
- Missing evidence is recorded as unknown or as an evidence gap, not as proof of
  absence.
- Re-running does not overwrite completed snapshots or historical findings.

## Current table mapping

```text
public.application_instances                 Assessment configuration (platform-owned)
public.artifacts                             immutable uploaded Evidence Package
contexla_estate.estate_assessment_runs       Assessment Run
contexla_estate.estate_evidence_items        package-relative Evidence Items
contexla_estate.estate_snapshots             normalized target Snapshot
contexla_estate.estate_snapshot_comparisons  immutable inventory comparison
contexla_estate.estate_inventory_items       normalized inventory/resources
contexla_estate.estate_relationships         typed inventory relationships
contexla_estate.estate_findings              deterministic and expert Findings
contexla_estate.estate_review_decisions      reviewer dispositions and rationale
public.capability_invocations                Capability/Processor execution provenance
```

The first slice uses one Drupal target per imported package. A separate Target
table should be introduced when a real assessment requires multiple targets or
live Connection bindings, not merely to complete an abstract model.

