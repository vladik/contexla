# Core concepts and boundaries

## Application

An Application represents a complete, independently useful business use case.
It may own Ecto schemas, tables, workers, supervision, services, UI, APIs,
schedules, reports, policies, and Application-facing integration contracts.

Examples include Digital Estate Assessment, Accessibility Monitor, Content
Integrity, and Content Transport.

## Application Instance

An Application Instance is one configured use of an installed Application. It
has a name, scope, settings, Connections, schedules, and history of Runs.

Five Drupal sites can be represented as five instances when they require
separate assessment scope and history, or as one instance containing five
targets when the user wants a single estate-level assessment. That is an
Application domain decision, not a tenancy mechanism.

## Application Operation

An Application Operation is a named business command exposed by an Application
to the UI, API, agents, and approved triggers. The Application SDK Definition
declares Operations and the owning Application implements their behavior.

Examples include `assessment.run`, `assessment.report`, `accessibility.check`,
`gate.evaluate`, and `transport.deliver`. An Operation is broader and more
domain-aware than a Tool: it may validate Application state, invoke multiple
Tools, enqueue durable work, persist domain results, or return a synchronous
decision.

```text
Application
  -> Application Instance
  -> Application Operation
  -> Run
  -> Tool Invocations
  -> Evidence, Findings, state, or external effects
```

An Operation may be invoked manually, by an authorized agent, through an API,
on a schedule, from a webhook/event, or by another authorized Application
Operation. These are invocation modes, not different Application types.

Operations declare command versus read semantics, a structured input schema,
required Tools where applicable, and whether explicit approval is required. The
platform creates an auditable Operation Invocation only after declaration,
version, transport, input, Tool availability, and approval checks pass.
Application UI, APIs, schedules, and agents must use this boundary rather than
calling an Operation callback directly.

## Trigger and Automation

A Trigger describes why or when an Application Operation starts: manual action,
schedule, API request, webhook, external event, or authorized internal event.
An Automation may eventually bind a configured Trigger to an Operation. Neither
term implies a generic user-editable workflow graph, and no generic Automation
entity should be introduced until a real Application requires one.

Applications may therefore support one-time assessments, recurring monitoring,
synchronous gates, event-driven validation, durable transport, archives, or
interactive investigations while sharing the same Operation and Run model.

## Connection

A Connection is configured access to an external system or endpoint. It records
the system type, endpoint and non-secret settings, references encrypted
credentials, and can be shared by multiple Application Instances when policy
allows.

Connections are installation-level platform resources; an Application Instance
binds to them rather than copying credentials.

## Connector

A Connector is an optional component installed in or near an external system.
It exposes native data or events that ordinary remote access cannot provide
cleanly.

Examples include a Drupal module that exports module/configuration inventory or
a Sitecore package that exposes item and presentation details. Not every
integration requires a Connector: direct API, database, filesystem, or uploaded
snapshot access may be sufficient.

Connectors do not contain Contexla Application business logic.

## Client

A Client handles low-level communication: authentication, requests, pagination,
rate limits, retries, protocol errors, and raw external identifiers. A Client
may speak directly to a system or to a Connector.

## Adapter

An Adapter lives on the Contexla side and implements a contract consumed by an
Application or shared acquisition service. It coordinates one or more Clients
and translates system-native data into stable structures expected by that
contract.

An Adapter is more than an HTTP wrapper, but it must not calculate unrelated
business findings. For example:

```text
Drupal Connector or JSON:API
          -> Drupal Client
          -> Estate Source Adapter
          -> normalized estate snapshot
          -> Digital Estate Assessment rules and findings
```

An Adapter can be reused where multiple Applications consume the same stable
contract. If Migration and Integrity require different meaning from Drupal
data, each may need a thin domain-specific Adapter over the same Client.

## Tool and Tool Invocation

A Tool is a small, versioned executable unit that performs one bounded
operation. It owns its machine-readable input/output schemas, implementation,
runtime, dependencies, permissions, limits, and tests. Examples include
`Extract PDF Text`, `Normalize Currency`, `Capture Screenshot`, and `Compare
Images`.

All external Tools use a common JSON process protocol, while each Tool has its
own operation-specific schemas. Applications pin exact Tool versions and invoke
them only through the Tool Runtime. A Tool does not own UI, schedules, domain
tables, or Application business decisions.

A Tool Invocation is the durable execution record. It is created before the
Oban execution job and pins the exact Tool ID, version, package checksum, actor,
Application Instance, parent Run when applicable, audit-safe input/output or
error code, Artifacts, status, and timestamps.

The formal Capability, Processor, and Capability Binding abstractions are
superseded by Tool. The complete normative contract is in
[Tool architecture and runtime](tool-runtime.md).

Authentication, Artifact storage, Oban retry behavior, trusted package
admission, and runtime supervision are platform infrastructure, not Tools. An
Adapter may call Tools during normalization, but source admission remains an
Adapter/platform trust boundary.

## Audit Events and safe failures

The platform records append-only Audit Events for current lifecycle actions
that are not already fully represented by a Run or Invocation, beginning with
Application Instance creation/configuration and source snapshot import. Events
contain actor and subject identity plus bounded metadata; configuration values,
credentials, exception messages, and arbitrary failure terms are excluded.

When a failure crosses an audit, persistence, API, or UI boundary, Contexla
retains a stable safe code derived from an internal atom or tagged tuple. Full
internal terms may be used transiently for control flow but are not serialized
with `inspect/1` into durable records or shown to users.

## Run, result, finding, and evidence

- **Run** — one auditable execution with status, timing, inputs, versioned
  configuration, and ownership.
- **Result** — structured output from a Run or Tool Invocation.
- **Finding** — an Application-domain conclusion such as a risk, mismatch, or
  missing integration.
- **Evidence** — immutable or versioned material supporting a finding: source
  data, hashes, screenshots, logs, comparison output, or reports.

## Registry and sharing scopes

- Application and Tool definitions are installed at the platform level and
  recorded in PostgreSQL.
- Application configuration pins exact Tool versions; installing a new Tool or
  version does not silently change an Instance.
- Connections are configured once per installation and may be bound to multiple
  instances.
- Adapters and Clients are code packages, reusable according to their contracts.
- Application Instances own configuration, Runs, findings, and instance-domain
  state.

