# Contexla

Contexla is an on-premise-first digital-content integration and automation
platform.

It provides a shared runtime for independently useful Applications that help
organizations understand, validate, move, monitor, govern, and preserve digital
content. Applications reuse platform Connectors, Adapters, and Capabilities
without being forced into one generic workflow or data model.

Contexla is not a CMS and does not compete with CMS products. It works across
CMSs, websites, APIs, document stores, search indexes, asset systems, and other
content infrastructure.

## Product thesis

Organizations increasingly need to answer questions such as:

- What content and infrastructure do we have?
- What changed?
- Is it complete, correct, accessible, and consistent?
- Is it safe to publish or move forward?
- What should happen next?

Contexla answers those questions through a portfolio of focused Applications.
The portfolio can grow one commercially useful solution at a time while sharing
a reliable BEAM/OTP and Oban foundation.

AI agents have two roles:

1. **Operate the platform** by translating intent into configuration and Runs,
   inspecting evidence, explaining results, and recommending actions.
2. **Extend the platform** by defining missing Capability contracts or creating
   isolated Processors that implement existing contracts.

AI is optional and is never the source of truth. Deterministic rules,
Connectors, evidence, validation, and auditable execution remain authoritative.
Every core workflow must be usable manually through UI or API when an
installation has no AI access.

## Initial commercial direction

The first proposed Application is **Digital Estate Assessment**. It addresses
current agency opportunities such as CMS modernization, Drupal estate audits,
Sitecore migration discovery, integration inventory, and accessibility
readiness.

The first version should produce a useful, evidence-backed assessment from a
controlled snapshot or a narrowly scoped Drupal integration. It should not try
to become a universal scanner before proving customer demand.

The initial business model is solution-led, platform-backed, and
service-assisted. Customers buy a defined assessment, modernization,
verification, or assurance outcome. Contexla is the reusable product foundation
that makes delivery repeatable and extensible; it is not initially sold as a
generic Application marketplace. Early deployments are curated for the agreed
solution without creating customer-specific code forks.

See the [solution-led commercial model](docs/product/solution-led-commercial-model.md).

## Architecture vocabulary

- **Application** — an independently useful business use case with its own
  domain, tables, jobs, UI, APIs, and reports.
- **Application Instance** — a configured use of an installed Application, such
  as an assessment of one Drupal estate. One installation may have many
  instances of the same Application.
- **Application Operation** - an Application-owned command exposed to the UI,
  API, agents, or approved triggers. Invoking an Operation may create a Run.
- **Connector** — an optional component installed in or near an external system
  when native access, events, or privileged data collection are needed.
- **Client** — low-level communication with an external API, database, file
  source, or Connector.
- **Adapter** — the Contexla-side implementation of an Application-facing
  contract. It coordinates Clients and translates external data into stable
  structures the Application understands.
- **Capability** — a stable, versioned contract describing what operation the
  platform can perform, including semantic purpose, input/output schemas, and
  allowed permissions.
- **Processor** — one versioned implementation of a Capability. A Processor
  supplies the runtime, entrypoint, dependencies, limits, and implementation
  configuration; it may be native Elixir, isolated Python, a CLI, or HTTP.
- **Capability Binding** — the explicit choice of Processor and configuration
  for a Capability at platform, Application, or Application Instance scope.
- **Capability Invocation** — one auditable execution that records the exact
  Capability, Processor, Binding, actor, input, output, and status.
- **Run** — one auditable execution of an Application or operation.
- **Artifact/Evidence** — durable output that supports a result, finding, or
  decision.

See [docs/README.md](docs/README.md) for the documentation map.

## Status

Contexla is at the commercial-validation and first architecture-proof stage.
The platform now compiles and boots without concrete Applications. Digital
Estate Assessment and Drupal compile independently and are loaded through the
SDK registry; the Application owns its PostgreSQL schema, migrations, execution,
reports, and UI surfaces behind generic platform routes.
External registered packages now start as real OTP Applications. Package builds
validate manifest identity against compiled definitions, Application migrations
run explicitly rather than during registry startup, and configured Instances
refuse to execute against a different installed Application version.
Application Operations now pass through a declared and auditable platform
boundary that enforces structured input, command/read transport, required
Capabilities, and authenticated approval before calling package code.
The platform owns the shared authenticated shell and visual system, while the
independent `contexla_ui` package gives Applications route-free components and
semantic styling without coupling them to platform web code.
Configured Instance surfaces now share a standard Application frame and proven
form/list-detail composition patterns. The Application SDK can generate an
independently compiled starter package that uses those contracts without
depending on the platform or Digital Estate Assessment.
The shell includes a context-aware Agent workspace with an honest unconfigured
state. It is a UI foundation only: no Agent provider, session persistence, or
tool execution is implemented yet.
The repository contains an executable first Digital Estate Assessment vertical
slice. An authenticated user can create an Assessment Instance, upload and
validate a Drupal snapshot, retain it as immutable evidence, queue an Oban Run,
normalize inventory through the Drupal Adapter, invoke the Composer Capability,
persist relationships and deterministic findings, inspect results, and produce
HTML or JSON report output. Reviewers can disposition deterministic findings
with an append-only rationale and add attributed expert findings. The slice is
also compares consecutive normalized snapshots as added, changed, and removed
inventory.

A read-only Drush collector spike has now been exercised against a disposable
Drupal 11 installation in both clean and synthetic-college states. Those
snapshots completed the full Artifact, Capability, Oban, persistence,
comparison, Finding, and JSON-report path. This is a stronger technical proof
than hand-authored fixtures, but it is still synthetic evidence; real college
evidence and customer review remain required for commercial validation.

See [the development guide](docs/development/getting-started.md) to run the
current platform.

