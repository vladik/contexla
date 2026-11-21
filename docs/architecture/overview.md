# Architecture overview

## Deployment model

The initial product is an on-premise-first modular monolith distributed as a
BEAM release. A customer may run it on a server, VM, container platform, or a
service such as Fly.io with PostgreSQL and suitable artifact storage.

One installation serves one organization. It may contain multiple users and
many Application Instances, but it does not initially implement cross-
organization membership or tenant isolation. Customers that need isolation run
separate installations.

Initial setup creates or guides creation of the first administrator. Production
releases must use a generated/one-time credential or explicit bootstrap secret
and require it to be changed; they must not ship a universal default password.

## Repository and package structure

```text
platform/                 Phoenix host, package registry, services, and runtime
ui/
  contexla_ui/            route-independent shared components and visual contract
applications/
  sdk/                    Application package contracts
  digital_estate_assessment/
capabilities/
  sdk/                    implementation-neutral Capability contracts
  bundled/                trusted first-party Capability definitions
processors/
  native/                 trusted native Processor implementations
integrations/
  sdk/
  drupal/
```

Each directory is a separate Mix project. A substantial Application is an
independently compiled OTP application. The platform depends on the Application
SDK, never on a concrete Application package. Source-linked development packages
and installed packages enter through the same registry contract.

## Shared platform responsibilities

Keep the platform core small:

- installed Application registry and lifecycle;
- Application Instance conventions;
- Application Operation declaration and invocation conventions;
- user authentication and authorization within one installation;
- encrypted Connections and secrets;
- Run and job execution conventions;
- Capability and Processor registry, scoped Bindings, and invocation runtime;
- artifact/evidence storage;
- notifications and basic observability;
- platform navigation and operational health.
- authenticated shell, global theme, and shared browser asset delivery.

Application-specific entities and findings belong to the Application.
Application-specific surfaces use the independent `contexla_ui` contract and
render inside the platform-owned shell; they never depend on `ContexlaWeb`.

Applications may expose one-time, scheduled, event-driven, synchronous, or
durable Operations without becoming generic workflows. Humans, agents, APIs,
schedules, and events invoke the same declared Operation boundary; auditable
execution is retained as a Run.

## Runtime

- OTP provides supervision, isolation, and in-process modularity.
- Oban provides durable work, retries, scheduling, uniqueness, and operational
  visibility.
- PostgreSQL stores platform and Application state.
- Artifact storage keeps snapshots, exports, reports, screenshots, and evidence.
- Applications request a Capability contract; the runtime resolves an Instance,
  Application, or Platform Binding and executes the selected Processor.
- PostgreSQL mirrors trusted code definitions and stores Bindings and
  Invocations. Bundled code remains authoritative and same-version definition
  drift is rejected.
- Native Processors run through the native Runner with contract validation and
  explicit timeouts.
- Python Processors will execute as isolated operating-system processes with
  locked dependencies, explicit limits, and structured input/output.

The Digital Estate Assessment package owns its worker, executor, domain services,
UI, reports, schemas, and migrations. It accesses Artifacts, Adapters,
Capabilities, jobs, and actor-scoped Instance services only through the bounded
typed functions supplied by `Contexla.ApplicationSDK.Runtime`. The SDK declares
the host service behaviour and the platform injects its implementation; an
Application never dynamically names platform functions or depends on the
platform implementation module.

Application Operations cross a platform-owned invocation boundary before
Application code executes. The boundary enforces declaration, pinned version,
command/read transport, input schema, required Capability availability, and
approval, then records a bounded Operation Invocation. An Application-owned Run
may be linked to that invocation without becoming platform-owned domain state.

Microservices and container-per-Processor sandboxing may become appropriate
later, but are not required to prove the model.

## Application installation and instances

An Application package is installed once without recompiling the platform. Its
manifest identifies its OTP application and SDK entry module. During controlled
installation, Contexla validates manifest/compiled-definition identity and runs
owned migrations explicitly. At startup, Contexla starts the package OTP
Application and registers its declared UI surfaces and Operations without
mutating the database. A user then creates one or more Application Instances,
for example:

```text
Installed Application: Digital Estate Assessment
  Instance: College public Drupal estate
  Instance: College intranet Drupal estate
  Instance: Legacy Sitecore estate
```

The platform owns the canonical `/applications/:instance_id` route and named
routes such as `/applications/:instance_id/:surface`. It resolves the
Application's one declared default Instance surface or requested named surface
from the runtime registry and mounts the LiveView dynamically. No concrete
Application route or LiveView is compiled into the platform. Generic sidebar
navigation lists configured Instances by name and Application icon; a
platform-owned chooser delegates setup to the selected package's one declared
new-Instance surface.

Installation is initially a vendor-controlled distribution and deployment
concern, not a buyer-facing marketplace workflow. Early customer releases
contain a small supported set of packages selected for the purchased solution.
The package and registry boundaries preserve future installation options without
making self-service installation a current commercial dependency.

Each Application owns one PostgreSQL schema and migration history. Instances
hold configuration and rows identified by `application_instance_id`; they are
not separate copies of code or separate schemas. For example,
`contexla_estate` is owned by the Digital Estate Assessment package while
platform tables remain in `public`.

An Instance is pinned to the exact Application version used to create it. The
initial runtime supports one active version per Application ID and refuses to
mount or execute an Instance when its pinned version differs. Upgrades therefore
require an explicit future compatibility/migration decision rather than silently
running old Instances with new code.

## Secrets and offline operation

- Store external credentials encrypted at rest in PostgreSQL using a key
  supplied outside the database.
- Redact secrets from logs and evidence.
- Pass narrowly scoped credentials to the execution component only when needed.
- Support installations with no external AI provider.
- Keep manual UI/API configuration and deterministic Runs fully functional when
  AI features are disabled.

