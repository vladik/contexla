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
platform/                 Phoenix release, catalog, binding, and runtime
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

Each directory is a separate Mix project today. A substantial Application is
an OTP application and owns its domain. Capability definitions and Processor
implementations remain separate even when v1 has only one Processor for a
Capability.

## Shared platform responsibilities

Keep the platform core small:

- installed Application registry and lifecycle;
- Application Instance conventions;
- user authentication and authorization within one installation;
- encrypted Connections and secrets;
- Run and job execution conventions;
- Capability and Processor registry, scoped Bindings, and invocation runtime;
- artifact/evidence storage;
- notifications and basic observability;
- platform navigation and operational health.

Application-specific entities and findings belong to the Application.

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

Microservices and container-per-Processor sandboxing may become appropriate
later, but are not required to prove the model.

## Application installation and instances

An Application package is installed once into a Contexla release. Its migrations
create its tables when the release is deployed or upgraded. A user then creates
one or more Application Instances, for example:

```text
Installed Application: Digital Estate Assessment
  Instance: College public Drupal estate
  Instance: College intranet Drupal estate
  Instance: Legacy Sitecore estate
```

Instances hold configuration and scope. They are not separate copies of code or
separate database schemas by default.

## Secrets and offline operation

- Store external credentials encrypted at rest in PostgreSQL using a key
  supplied outside the database.
- Redact secrets from logs and evidence.
- Pass narrowly scoped credentials to the execution component only when needed.
- Support installations with no external AI provider.
- Keep manual UI/API configuration and deterministic Runs fully functional when
  AI features are disabled.

