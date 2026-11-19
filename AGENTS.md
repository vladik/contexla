# Working on Contexla

This repository is being developed proof by proof. Preserve the product
boundaries below when planning or changing it.

## Before making changes

1. Read `README.md` and `docs/README.md`.
2. Read the documents linked for the area being changed.
3. Check Git status and preserve unrelated user changes.
4. State assumptions when a decision is not documented.

## Product constraints

- Contexla is a digital-content integration and automation platform, not a CMS.
- Build a portfolio of focused Applications, not one universal workflow product.
- Optimize first for a small agency that must ship and sell incrementally.
- The initial deployment model is one organization per installation. Do not add
  organizations, tenants, or workspaces without an explicit product decision.
- Applications are installed once and may have many Application Instances.
- The platform depends only on Application/Integration SDKs and must compile and
  boot with zero concrete packages. Never add a concrete Application or
  Integration as a platform dependency.
- AI is optional. Core workflows must remain usable manually through UI or API.
- Agents may operate and extend the platform, but deterministic execution and
  stored evidence are authoritative.
- Prefer a modular monolith and OTP applications over microservices.
- Do not add a generic visual workflow builder in the initial product.
- Do not create empty future Applications or abstractions without demonstrated
  reuse.

## Architectural placement rule

Use this test before adding functionality:

```text
Complete independent business use case?  -> Application
Configured use of an Application?         -> Application Instance
Native component in/near external system? -> Connector
Low-level external communication?         -> Client
Implements an Application-facing external-system contract? -> Adapter
Small reusable executable operation?      -> Capability
Concrete implementation of a Capability? -> Processor
Scoped selection/configuration of a Processor? -> Capability Binding
Infrastructure needed by many Applications? -> Core/Runtime
```

Adapters may be reusable across Applications only when their contract is truly
shared. Do not make an Adapter generic merely to avoid two small domain-specific
translations.

## Implementation principles

- Applications own their domain and database tables.
- Applications also own their services, migrations, workers, execution, reports,
  UI surfaces, and browser assets. The platform exposes only generic routes and
  bounded SDK runtime services.
- Shared platform code owns only cross-Application concerns.
- Use Oban for durable jobs and OTP supervision for runtime processes.
- Store secrets encrypted and never include them in logs, artifacts, prompts, or
  Capability input unless explicitly required and authorized.
- Applications depend on Capability contracts, never directly on Processor
  modules, scripts, or binaries.
- Processors own implementation details: runtime, entrypoint, dependencies,
  limits, and implementation configuration.
- Python Processors own isolated dependencies and communicate through the
  Capability's structured input/output contract.
- Execute Processors only through the Capability runtime so validation,
  binding, permissions, provenance, and invocation history cannot be bypassed.
- Treat generated code as untrusted until its manifest, permissions, tests, and
  execution have been validated.
- Prefer deterministic validation for correctness; use AI for planning,
  interpretation, suggestions, and bounded generation.
- Keep Runs auditable and retain evidence for important findings.
- Start integrations with the least invasive acquisition method that can prove
  value, such as uploaded snapshots, APIs, or read-only collection.

## Documentation rules

- Update the relevant documentation when changing a product boundary or public
  contract.
- Record consequential, hard-to-reverse architecture decisions as ADRs under
  `docs/decisions/`.
- Mark hypotheses as hypotheses. Do not present an unvalidated market claim as a
  settled requirement.
- Keep terminology consistent with `docs/architecture/concepts.md`.

## Current sequence

1. Validate Digital Estate Assessment with real buyer conversations and a
   manually deliverable assessment shape.
2. Run the implemented fixture-backed vertical slice against real college
   evidence and refine its input/output contract.
3. Add an isolated Python Processor only for a real assessment operation that
   the native slice cannot reasonably provide.
4. Add agent operation only after the deterministic assessment is accepted.
5. Prove reuse through a second paid or strongly validated Application.

Do not implement later roadmap phases unless the current proof requires them.

## Current implementation state

- Digital Estate Assessment is independently compiled and source-linked through
  the runtime registry; it is not a platform dependency.
- The platform owns stable generic Application routes and dynamically mounts
  package-declared LiveView surfaces.
- The Application owns the `contexla_estate` PostgreSQL schema and migration
  lifecycle. Instances share its tables through `application_instance_id`.
- The fixture-backed Digital Estate Assessment vertical slice is implemented:
  create Instance, upload/validate Artifact, queue Oban Run, normalize through
  the Drupal Adapter, invoke Composer Capability, persist evidence/inventory/
  relationships/findings, inspect results, and render HTML/JSON reports.
- Findings preserve deterministic versus expert origin, and status changes are
  recorded as append-only Review Decisions with reviewer and rationale.
- Consecutive successful Snapshots for an Instance and target are compared by
  stable inventory identity, preserving added, changed, and removed values.
- A read-only Drush collector spike under `connectors/drupal_snapshot/` has been
  run against a disposable Drupal 11 site. Clean and seeded synthetic-college
  snapshots completed the real Artifact, native Composer Processor, Oban,
  persistence, comparison, deterministic Finding, and report path. Aggregate
  content/media counts are normalized as evidence-backed Resources.
- The synthetic proof is not real buyer evidence and must not be presented as
  commercial validation. Local DDEV database checkpoints and generated ZIPs are
  development state, not repository fixtures or customer artifacts.
- The next priority is real college evidence and customer review. Refine the
  snapshot contract, rules, and report from that evidence before adding agents,
  Python Processors, live Connections, or a second Application.

