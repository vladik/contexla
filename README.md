# Contexla

Contexla is an on-premise-first digital-content integration and automation
platform.

It provides a shared runtime for independently useful Applications that help
organizations understand, validate, move, monitor, govern, and preserve digital
content. Applications reuse platform Connectors and Adapters
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
2. **Extend the platform** by building Application-owned Processors and Workers
   that implement bounded operations within their domain.

AI is optional and is never the source of truth. Deterministic rules,
Connectors, evidence, validation, and auditable execution remain authoritative.
Every core workflow must be usable manually through UI or API when an
installation has no AI access.

## Business direction

Contexla is a portfolio-led product asset for a small CMS-focused agency.
Focused, independently useful Applications provide working demonstrations for
marketing and sales, reusable foundations for client delivery, and a path from
consulting projects to integration, support, managed operation, and future
licensing. An Application may be built as a bounded market hypothesis before a
contract exists; it must still have a clear standalone job, demonstrable value,
and an explicit stop condition.

The initial business model is solution-led, platform-backed, and
service-assisted. Marketing leads with a recognizable customer problem and
outcome. Contexla is the reusable delivery foundation, not initially a generic
Application marketplace. Early deployments are curated for the agreed solution
without creating customer-specific code forks.

Digital Estate Assessment is retained as an architecture proof, not the current
commercial priority. The current first serious portfolio hypothesis is
**Content Integrity Monitor**: detect when important facts are missing, stale,
or inconsistent across authoritative sources and delivered representations.

See [business intent and current priorities](docs/product/business-intent-and-priorities.md)
and the [solution-led commercial model](docs/product/solution-led-commercial-model.md).

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
- **Run** — one auditable execution of an Application or operation.
- **Artifact/Evidence** — durable output that supports a result, finding, or
  decision.

See [docs/README.md](docs/README.md) for the documentation map.

## Status

Contexla is at the commercial-validation and first architecture-proof stage.
Applications own their Processors (pure functions) and Workers directly.
The former Capability/Processor/Binding and unified Tool runtimes have both
been removed.
The platform now compiles and boots without concrete Applications. Digital
Estate Assessment and Drupal compile independently and are loaded through the
SDK registry; the Application owns its PostgreSQL schema, migrations, execution,
reports, and UI surfaces behind generic platform routes.
External registered packages now start as real OTP Applications. Package builds
validate manifest identity against compiled definitions, Application migrations
run explicitly rather than during registry startup, and configured Instances
refuse to execute against a different installed Application version.
Application Operations now pass through a declared and auditable platform
boundary that enforces structured input, command/read transport, and
authenticated approval before calling package code.
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
Installation administrators now have a read-only Operations Console for
bounded readiness, registered package state, recent Application Operation Invocations, Oban jobs, and lifecycle audit activity. The
console uses safe error/reference data and links to affected Application Instances
without copying Application-owned Runs or exposing payloads and secrets.
Administrators can export the same bounded operational evidence as a checksummed
support bundle. An isolated automated failure drill verifies that useful
references survive while planted credentials, content, payloads, job arguments,
error details, audit metadata, and user email addresses do not leak.
The repository contains an executable first Digital Estate Assessment vertical
slice. An authenticated user can create an Assessment Instance, upload and
validate a Drupal snapshot, retain it as immutable evidence, queue an Oban Run,
normalize inventory through the Drupal Adapter, process the inventory,
persist relationships and deterministic findings, inspect results, and produce
HTML or JSON report output. Reviewers can disposition deterministic findings
with an append-only rationale and add attributed expert findings. The slice is
also compares consecutive normalized snapshots as added, changed, and removed
inventory.

A read-only Drush collector spike has now been exercised against a disposable
Drupal 11 installation in both clean and synthetic-college states. Those
snapshots completed the full Artifact, Oban, persistence, comparison, Finding,
and JSON-report path. This is a stronger technical proof
than hand-authored fixtures, but it is still synthetic evidence; real college
evidence and customer review remain required for commercial validation.

See [the development guide](docs/development/getting-started.md) to run the
current platform.

The independent Content Integrity Monitor package now provides the first
bounded portfolio-product slice: Application-owned Monitors, Sources, Facts,
Runs, Observations, Issues, and Evidence; exact JSON/HTML extraction processors; and a synthetic external content chain
for local demonstration. This remains a market hypothesis until prospects
validate and fund a pilot or integration.

