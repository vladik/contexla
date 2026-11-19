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

## Architecture vocabulary

- **Application** — an independently useful business solution with its own
  domain, tables, jobs, UI, APIs, and reports.
- **Application Instance** — a configured use of an installed Application, such
  as an assessment of one Drupal estate. One installation may have many
  instances of the same Application.
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
The repository contains a Phoenix/PostgreSQL platform skeleton, Application and
Integration and Capability SDK contracts, the bundled Digital Estate Assessment
Application, a bundled native Processor, the bundled Drupal Integration
definition, password-based administrator authentication, and persistent
Application Instances. The Capability catalog, scoped binding resolution,
contract validation, and auditable native invocation path are implemented. It
does not yet implement the normalized assessment inventory, findings, or
assessment UI. The backend can validate and retain Drupal snapshot ZIPs as
evidence-bearing Artifacts.

See [the development guide](docs/development/getting-started.md) to run the
current skeleton.

