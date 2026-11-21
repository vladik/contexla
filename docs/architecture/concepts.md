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
domain-aware than a Capability: it may validate Application state, invoke
multiple Capabilities, enqueue durable work, persist domain results, or return a
synchronous decision.

```text
Application
  -> Application Instance
  -> Application Operation
  -> Run
  -> Capability Invocations
  -> Evidence, Findings, state, or external effects
```

An Operation may be invoked manually, by an authorized agent, through an API,
on a schedule, from a webhook/event, or by another authorized Application
Operation. These are invocation modes, not different Application types.

Operations declare command versus read semantics, a structured input schema,
required Capabilities, and whether explicit approval is required. The platform
creates an auditable Operation Invocation only after declaration, version,
transport, input, Capability, and approval checks pass. Application UI, APIs,
schedules, and agents must use this boundary rather than calling an Operation
callback directly.

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

## Capability

A Capability is a stable contract for a small reusable executable operation. It
describes **what** Contexla can do, independent of language or implementation.
It declares:

- identity, semantic purpose, and contract version;
- structured input, output, and error schemas;
- permissions the operation is allowed to request;
- determinism, side effects, and idempotency semantics.

Applications depend on Capability identities and contract versions. They do not
depend directly on a Python file, Elixir module, CLI, or service.

## Processor

A Processor is one concrete, versioned implementation of a Capability. It
describes **how** the operation runs:

- runtime and entrypoint;
- code/package identity and dependencies;
- implementation configuration schema;
- requested permissions;
- timeout and resource limits.

Processors may use native Elixir, isolated Python, an external executable, or
an HTTP service. One Capability can have multiple Processors without changing
the Application:

```text
Application -> Capability contract -> Capability Binding -> Processor -> Runner
```

For example, `Extract PDF Text` may be implemented by a Python/PyMuPDF
Processor, a Rust CLI Processor, or a remote approved service Processor.

## Capability Binding and Invocation

A Capability Binding selects one Processor and its approved configuration and
permissions. Resolution uses the most specific active binding:

```text
Application Instance -> Application -> Platform
```

An instance-specific Processor can therefore handle one customer's format
without redefining the shared Capability. Promote narrow contracts or
Processors upward only after reuse is demonstrated.

A Capability Invocation is the auditable execution record. It pins the
Capability contract, Processor version, resolved Binding, actor, Application
Instance, input, output/error, status, and timestamps.

The Runner is internal runtime infrastructure that executes the selected
Processor type. It is not itself a Capability.

Useful Capability families are:

```text
Acquire -> Extract -> Normalize -> Transform -> Compare -> Validate
        -> Decide -> Transport -> Preserve -> Report -> Act -> AI Assist
```

Authentication, Artifact storage, Oban retry behavior, trusted ZIP admission,
and runtime supervision are platform infrastructure, not user-visible
Capabilities. An Adapter may call Capabilities during normalization, but source
admission remains an Adapter/platform trust boundary.

## Run, result, finding, and evidence

- **Run** — one auditable execution with status, timing, inputs, versioned
  configuration, and ownership.
- **Result** — structured output from a Run or Capability invocation.
- **Finding** — an Application-domain conclusion such as a risk, mismatch, or
  missing integration.
- **Evidence** — immutable or versioned material supporting a finding: source
  data, hashes, screenshots, logs, comparison output, or reports.

## Registry and sharing scopes

- Application, Capability, and trusted Processor definitions are installed at
  the platform level and mirrored into PostgreSQL.
- Capability Bindings select Processors at platform, Application, or Instance
  scope; Instance wins over Application, which wins over Platform.
- Connections are configured once per installation and may be bound to multiple
  instances.
- Adapters and Clients are code packages, reusable according to their contracts.
- Application Instances own configuration, Runs, findings, and instance-domain
  state.

