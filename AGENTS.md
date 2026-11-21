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
- Use a solution-led, platform-backed, service-assisted commercial model. Sell a
  defined customer outcome first; explain Contexla as the delivery foundation
  second.
- Treat consulting, implementation, managed assurance, support, and future
  licensing as complementary revenue paths. Do not optimize only for license
  sales.
- The initial deployment model is one organization per installation. Do not add
  organizations, tenants, or workspaces without an explicit product decision.
- Applications are installed once and may have many Application Instances.
- Use **Application**, not "App", in Contexla product UI, documentation, and
  public contracts. Framework-standard names such as OTP app or `app.js` may
  remain. **Solution** is a commercial offer that may combine Applications,
  Integrations, and services; it is not a platform entity.
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
- Early customer distributions are curated supported package combinations, not
  a marketplace. Never create customer forks; represent differences through
  Instances, configuration, Connections, Bindings, and bounded extensions.
- Do not require on-premise installation for a bounded snapshot engagement when
  an approved evidence package and agreed secure processing environment satisfy
  the customer. Keep customer-hosted execution available when policy requires
  it.

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
  domain UI surfaces, and optional namespaced browser assets. The platform owns
  the authenticated shell, global theme/assets, navigation, and generic routes.
  Shared route-independent components belong in `contexla_ui`; Applications
  must never depend on `ContexlaWeb`.
- Reuse and extend the established `contexla_ui` primitives and shell patterns.
  Do not create parallel Application-local buttons, inputs, modals, tables,
  themes, or full-page layouts unless the shared contract genuinely cannot
  express a validated requirement.
- Preserve the shared hierarchy: platform shell, contextual surface header,
  then content canvas. Public authentication and error pages never render inside
  the authenticated shell; flash messages are viewport-level toasts.
- Build Instance surfaces with the shared Application frame and use the
  documented overview, collection, list/detail, sectioned form, Run, comparison,
  report, and settings patterns. Start new packages with the Application SDK
  generator; generated packages must remain independent of the platform and
  concrete Applications.
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
- Execute Application Operations only through the platform Operation boundary.
  Commands use POST or trusted runtime services; GET is reserved for declared
  read Operations. Enforce input schemas, required Capabilities, approval, safe
  audit projection, and Invocation history before calling Application code.
- Keep package lifecycle stages explicit: validate/build, migrate/install, then
  discover/start. Registry startup must not run Application migrations, and an
  Instance must never execute against a different Application version than the
  one it pins.
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
Before adding platform infrastructure, identify the paid or strongly validated
solution that requires it now. See
`docs/product/solution-led-commercial-model.md` for the commercial build gate.

## Current implementation state

- Digital Estate Assessment is independently compiled and source-linked through
  the runtime registry; it is not a platform dependency.
- The platform owns stable generic Application routes and dynamically mounts
  package-declared LiveView surfaces.
- External registered OTP Applications are started with their supervision trees.
  Package manifests are checked against compiled definitions, Application
  migrations run through an explicit task, and Instance access enforces the
  exact registered version.
- Application Operations have declared command/read and input contracts. The
  platform records Operation Invocations and links Application-owned Runs when
  supplied; Digital Estate Assessment starts Runs through this boundary.
- Applications use explicit typed `Contexla.ApplicationSDK.Runtime` functions
  for shared host services. Dynamic platform function dispatch is not part of
  the SDK contract.
- Application packages declare a shared icon, one new-Instance surface, and one
  default Instance surface. The sidebar is Instance-first and canonical
  `/applications/:instance_id` URLs resolve through that default declaration.
- Every Instance has platform-owned General settings for its name and optional
  icon override. Every Application declares one settings surface for its own
  mutable domain configuration; configuration updates remain Application-
  validated through the SDK boundary.
- The platform shell includes a context-aware Contexla Agent workspace with
  Chat and Activity views. It currently exposes only an honest unconfigured
  state; no AI provider, Agent Session persistence, tool execution, or approval
  runtime is implemented. Agent Sessions must remain separate from authoritative
  Application Runs and Capability Invocations.
- `contexla_ui` provides the shared Application frame and demonstrated layout
  patterns. The SDK starter generates an independently compiled package using
  those contracts; it is scaffolding, not a bundled product Application.
- The Application owns the `contexla_estate` PostgreSQL schema and migration
  lifecycle. Instances share its tables through `application_instance_id`.
- The fixture-backed Digital Estate Assessment vertical slice is implemented:
  create Instance, upload/validate Artifact, queue Oban Run, normalize through
  the Drupal Adapter, invoke Composer Capability, persist evidence/inventory/
  relationships/findings, inspect results, and render HTML/JSON reports. The
  HTML report includes decision and scope, method, declared limitations,
  inventory, comparison, finding provenance, review history, and evidence.
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

