# Tool architecture and runtime

## Status and decision

This document is the normative technical design for executable Tools in
Contexla. It replaces the earlier formal separation between Capability
contracts, Processor implementations, and Capability Bindings.

The implementation now uses the unified `tools` and `tool_invocations` model.
The migration converts historical Capability/Processor invocation data into
retired Tool records so operational provenance is retained. The Composer
dependency proof now executes as one bundled Tool.

The v1 decision is:

> A Tool is a small, versioned executable unit that performs one bounded
> operation.

A **Tool Package** is the distributable representation of a Tool when one is
needed. A trusted Elixir Tool compiled into a Contexla release does not need to
exist as a standalone ZIP, while an installed Python, JavaScript, Rust, Go, or
CLI Tool normally does.

## Why Tool is one concept

Every executable operation already needs a name, version, purpose, input and
output schemas, implementation, runtime, dependencies, permissions, limits,
and tests. Separating the operation contract from its implementation created
Capability, Processor, and Binding entities without demonstrated business
value.

Contexla therefore uses one formal unit:

```text
Application or Agent
        -> Tool
        -> Tool Invocation
```

There is no formal Capability, Processor, or Capability Binding in the target
v1 model. "Capability" may be used in ordinary prose, such as saying that a
Tool gives Contexla PDF extraction capability, but it is not a package type,
registry entity, or database entity.

## Boundary between Application and Tool

An Application is an independently useful business product. It owns durable
domain state, business rules, Runs, findings, reports, schedules, and domain
UI. A Tool performs one bounded operation and returns a structured result.

```text
Application
  owns: monitors, policies, observations, findings, verdicts, Runs

Tool
  owns: one executable operation, schemas, implementation, dependencies, tests
```

A Tool must not own:

- a Contexla Application domain or domain tables;
- platform or Application UI;
- its own schedules or Oban jobs;
- independent business workflow state;
- direct writes to Application tables;
- unrestricted platform, database, filesystem, or credential access.

For example, `Validate PDF Metadata` and `OCR PDF Images` are Tools. An
Accessibility Application decides which documents to inspect, invokes the
Tools, combines their results, applies policy, persists findings, and presents
the operational view.

## Relationship to other extension concepts

```text
Application          independently useful business product
Application Instance configured use of an Application
Application Operation action exposed to UI, API, Agent, or approved trigger
Tool                 bounded executable unit
Tool Invocation      durable record of one requested Tool execution
Adapter              maps an external system into an Application contract
Client               performs low-level external communication
Connector            optional component installed in/near an external system
Connection           stored endpoint configuration and encrypted credentials
Run                  durable Application execution
Artifact             immutable/versioned file-like input or output
Evidence             material supporting an Application result or decision
Agent                discovers, configures, creates, and operates
```

An Adapter may invoke Tools for bounded computation. A Tool does not become an
Adapter merely because it performs HTTP requests: an Adapter has the additional
responsibility of translating an external system into a stable contract used by
an Application.

## Tool identity and immutability

A Tool version is identified by:

```text
tool_id + version + package_sha256
```

`tool_id` is a stable reverse-domain identifier, for example:

```text
com.contexla.pdf.validate-metadata
```

Versions use semantic versioning where practical. Once approved or used by an
Invocation, a Tool version is immutable. Any change to code, schemas,
dependencies, declared permissions, entrypoint, or observable behavior creates
a new version and package checksum.

Application configuration pins an exact Tool version. Installing another
version never changes an existing Application Instance automatically.

## Tool manifest

The package contains a machine-readable manifest. JSON is the v1 interchange
format; an SDK may expose language-native builders that emit the same manifest.

Minimum manifest shape:

```json
{
  "schema_version": "1",
  "id": "com.contexla.pdf.validate-metadata",
  "version": "1.0.0",
  "name": "Validate PDF Metadata",
  "description": "Checks declared PDF metadata requirements.",
  "runtime": {
    "type": "python",
    "version": ">=3.12,<3.14",
    "entrypoint": ["python", "tool.py"]
  },
  "input_schema": {},
  "output_schema": {},
  "permissions": ["artifact:read"],
  "timeout_ms": 60000,
  "resource_limits": {
    "memory_mb": 512,
    "max_output_bytes": 1048576
  },
  "worker": {
    "profile": "document_tools",
    "platform": "linux",
    "architectures": ["x86_64"],
    "features": ["python-3.12"]
  }
}
```

The exact JSON Schema for this manifest belongs in the Tool SDK when the
runtime refactor begins. The architectural requirements are:

- stable identity and immutable version;
- human-readable purpose;
- runtime and entrypoint;
- structured input and output schemas;
- requested permissions;
- timeout and resource limits;
- worker compatibility requirements;
- package integrity and provenance outside or alongside the manifest.

Worker requirements describe compatibility. They must not be arbitrary shell
instructions for installing operating-system packages.

## Package contents

A typical external Tool Package is:

```text
tool.zip
|-- manifest.json
|-- tool.py, executable, or runtime source
|-- requirements.lock / package-lock.json / equivalent
|-- tests/
|-- fixtures/
`-- README.md
```

Language-specific examples:

```text
Python       source plus locked dependencies
JavaScript   source plus package lock
Rust / Go    reviewed source or platform-specific compiled executable
Elixir       normally trusted code bundled in the Contexla release
CLI          executable plus required runtime/package metadata
```

Packages must not contain credentials, production content fixtures, customer
secrets, or mutable environment directories such as `.venv`.

## Common execution protocol

External Tools use a strict process protocol:

```text
stdin      one structured JSON request
stdout     one structured JSON response envelope and nothing else
stderr     bounded diagnostics and logs
exit code  process execution status
```

Success response:

```json
{
  "status": "ok",
  "output": {}
}
```

Handled Tool failure:

```json
{
  "status": "error",
  "error": {
    "code": "invalid_pdf",
    "message": "The file is not a readable PDF."
  }
}
```

Libraries and Tool code must never log to stdout. Invalid JSON, multiple JSON
documents, output beyond the declared limit, an unexpected exit, or a missing
response is an execution failure normalized by the Tool Runtime.

Exit handling is deterministic:

- exit code `0` requires a valid `status: ok` response;
- a non-zero exit may include one valid `status: error` response for a handled
  Tool error;
- exit `0` with an error response, non-zero exit with a success response, or a
  non-zero exit without a valid response is a protocol/process failure.

Trusted native Elixir Tools may be invoked as functions instead of child
processes, but they obey the same logical input/output schemas, error model,
permission checks, versioning, and Invocation provenance.

## Files and Artifacts

Large or binary data does not travel inside JSON. The Tool Runtime stages
authorized Artifact inputs in a bounded input directory and provides a separate
output directory:

```text
/input     read-only staged files
/output    files produced by the Tool
```

JSON contains logical file descriptors rather than host paths. The runtime
maps those descriptors to staged paths and imports approved output files as
Artifacts after successful execution. A Tool cannot select arbitrary host
paths.

The JSON response returns output descriptors and structured metadata, not
megabytes of encoded file content. Contexla records Artifact identity,
checksum, size, media type, provenance, and retention information.

## Durable Invocation lifecycle

An Invocation represents requested work, not merely a process that happened to
start. Contexla creates the Invocation before enqueueing execution.

The Invocation and Oban job must be inserted atomically in one PostgreSQL
transaction:

```text
Application requests Tool execution
        -> insert Invocation: pending
        -> insert ToolInvocationJob
        -> commit
```

The lifecycle is:

```text
pending -> running -> succeeded
                   -> failed
                   -> timed_out
                   -> cancelled
                   -> pending (bounded technical retry)
```

At minimum an Invocation records:

- Tool ID, version, and package checksum;
- Application and Application Instance context;
- optional parent Application Run;
- requesting actor or Agent Session;
- status and timestamps;
- safe, schema-controlled input and output projections;
- normalized error code;
- produced Artifact references;
- worker identity and attempt metadata needed for support.

Secrets, raw credentials, unrestricted logs, internal exception text, and
large content payloads are excluded from durable Invocation data.

An Oban retry continues the same logical Invocation. Attempt details may use
Oban metadata initially; introduce a separate attempt table only if operational
evidence proves it necessary.

## Retry ownership and idempotency

The platform execution layer owns technical reliability:

- worker crash or disappearance;
- child process failing to start;
- temporary Artifact storage failure;
- temporary worker-local cache failure;
- bounded retry and timeout enforcement.

The Application owns business retry semantics:

- whether an HTTP 404 is a finding or retryable condition;
- whether a document should be analyzed again;
- whether a migration item may be retried;
- whether partial Tool results are acceptable;
- how repeated results affect domain state.

Tool manifests must declare enough behavior for safe execution, including
whether the operation has external side effects and whether repeated execution
is safe. Tools with external writes require explicit approval and an
Application-provided idempotency strategy where applicable.

## Application consumption

Applications invoke Tools through one authenticated Tool Runtime API. They do
not start Tool commands, locate virtual environments, or read Tool Package
files directly.

```text
User / Agent
     -> Application Operation
     -> Application Run
     -> request Tool Invocation
     -> Oban ToolInvocationJob
     -> compatible Tool Worker
     -> Tool
     -> structured result and Artifacts
     -> Application interprets and persists domain results
```

The Application owns orchestration:

- which Tools are required;
- their exact pinned versions;
- sequential or parallel execution;
- preparation and mapping of input;
- aggregation of results;
- business failure and retry rules;
- persistence of observations, findings, verdicts, and evidence.

Contexla does not introduce a generic workflow graph for v1. An Application
worker or service coordinates Tool Invocations according to its domain. A
general composition abstraction is added only after repeated implementations
demonstrate the same need.

### Multiple Tools for one Artifact

An Application may invoke several Tools against the same Artifact:

```text
PDF Artifact
  |-- Validate PDF Metadata Tool
  |-- Validate PDF Structure Tree Tool
  `-- OCR PDF Images Tool
          -> Application aggregates results
          -> Findings and Evidence
```

Independent Invocations may run in parallel. A dependent Tool starts only after
its required predecessor has succeeded and produced the required structured
output or Artifact. Each Tool execution retains its own Invocation provenance.

## Runtime roles and multi-machine execution

Contexla remains one modular codebase and release. Machines start different
runtime roles and Oban queues through configuration:

```text
web role
  Phoenix UI/API; no heavy Tool queues

worker role
  ordinary Application and platform jobs

tool_worker role
  Tool Runtime and selected Tool queues
```

All roles share PostgreSQL and Artifact storage. They do not require direct
HTTP calls to one another. Oban coordinates durable work through PostgreSQL.

Tools are routed by compatible worker queue/profile, not by creating one
service per Tool:

```text
light_tools
document_tools
browser_tools
gpu_tools
```

One generic `ToolInvocationJob` loads an Invocation, resolves the exact Tool
version, verifies worker compatibility, prepares the local environment, runs
the Tool, validates the response, imports Artifacts, and completes the
Invocation.

The same Contexla code may be deployed to web, worker, and Tool Worker
machines. Initially the same image may contain all prerequisites. Later a
heavier Tool Worker image may contain Chromium, PDFium, OCR, or GPU libraries
while still running the same Contexla Tool Runtime code.

## Registry, storage, and worker cache

PostgreSQL stores control state:

```text
Tool identity, version, manifest, schemas, status
package checksum and Artifact reference
approval and installation metadata
Invocation state and audit-safe projections
```

Artifact storage retains immutable package bytes and produced files:

```text
Tool ZIPs
locked dependencies/build outputs where approved
Invocation input/output Artifacts
evidence files
```

Eligible Tool Workers maintain disposable local caches:

```text
downloaded immutable packages
verified unpacked package directories
Tool-specific Python virtual environments
prepared executables
```

The package checksum keys the cache. Deleting a worker cache must not delete
the authoritative package or Invocation history. A different eligible worker
can download and prepare the same immutable Tool version.

## Worker compatibility

A worker advertises its profile and supported runtime features. Before claiming
or executing an Invocation, the platform verifies compatibility with:

- operating system and CPU architecture;
- runtime type and supported version;
- required worker features such as Chromium, PDFium, OCR, or GPU;
- configured queue/profile;
- resource limits the worker can enforce.

A Tool requiring an unsupported system dependency is not ready for execution.
Contexla reports that an administrator must deploy or update a compatible
worker profile. A Tool Package must not mutate the worker operating system to
make itself compatible.

## Development paths

### Bundled Tools

Bundled Tools are developed, reviewed, tested, and shipped by the Contexla
team. Trusted Elixir Tools may compile into the release. External bundled Tools
may still use the package protocol so development and production exercise the
same boundary.

```text
source -> tests -> package/build -> release assembly -> explicit version use
```

### Customer-developed Tools

Customers or delivery partners use the Tool SDK, manifest schema, test harness,
and packaging command:

```text
implementation -> local contract tests -> Tool Package -> review -> install
```

Customer Tools remain separate versioned packages. They do not create a fork of
the Contexla platform or an Application.

### AI-generated Tools

AI generation is initially a controlled development workflow, not autonomous
production installation. The Agent determines the missing bounded operation
and asks only for necessary information:

- desired behavior and examples;
- input and output requirements;
- permitted network, filesystem, and Artifact access;
- dependencies and target worker profile;
- time and resource expectations;
- fixtures and success/failure cases.

The Agent generates:

```text
manifest.json
implementation
locked dependencies
tests and fixtures
README and installation instructions
```

V1 limits AI-generated Tools to a supported reviewed language/runtime, expected
to begin with Python. The generated ZIP is not trusted merely because it passes
tests.

```text
generate -> developer review -> CI validation -> package approval
         -> supported distribution/install -> explicit enablement
```

Production Agents must not silently install, enable, replace, or execute
generated code. This preserves a useful commercial path for paid custom Tool
development, review, deployment, and support while avoiding a premature
untrusted-code platform.

## Installation and deployment

Early customer distributions are curated. A Tool is installed through a
reviewed software-delivery process:

1. validate the manifest and package structure;
2. verify the checksum and supported publisher/provenance information;
3. scan and audit locked dependencies;
4. run contract, fixture, and security tests;
5. confirm a compatible worker profile exists;
6. retain the immutable package as an Artifact;
7. register Tool metadata in PostgreSQL;
8. prepare or validate its runtime environment on eligible workers;
9. require explicit administrator approval;
10. make the exact version available for Application configuration.

V1 may perform these steps through development/CI and release assembly rather
than a self-service production upload screen. A marketplace, autonomous install
flow, and arbitrary dynamic dependency installation are not required.

Installing a Tool and configuring an Application to use it are separate acts.
Installation makes a version available. Application configuration explicitly
pins it for a particular use.

## Permissions, credentials, and secrets

Tools declare requested permissions. Installation approves a bounded subset.
An Invocation receives only the permissions and resources required for its
operation.

Examples include:

```text
artifact:read
artifact:write
network:http
connection:use
```

Raw secrets must not be included in prompts, manifests, package files, logs, or
durable audit projections. When a Tool is authorized to use a Connection, the
runtime brokers the minimum required credential material for that Invocation.
The Tool receives no general credential-store or PostgreSQL access.

Network access is denied unless declared and approved. Filesystem access is
limited to the Tool package, its prepared environment, and bounded Invocation
input/output directories.

## Dependency isolation and security boundary

Each Python Tool version owns a separate virtual environment. One Tool's Python
dependencies cannot upgrade or mutate another Tool's environment. Rust, Go,
JavaScript, and CLI Tools similarly own their package/build dependencies.

A virtual environment provides dependency isolation, not a security sandbox.
Therefore v1 executes only reviewed and approved Tool code. Strong isolation
for automatically executed untrusted code would require an additional sandbox,
container, VM, or remote execution boundary. That infrastructure is deferred
until customer demand justifies it.

Heavy libraries such as Chromium, Playwright browsers, PDFium, OCR engines, or
GPU drivers belong to compatible worker profiles when they cannot be safely
owned entirely by one package. Different Tool versions may still own different
user-space libraries where the runtime and loader can isolate them.

## Package trust and provenance

V1 requires:

- immutable Tool ID and version;
- SHA-256 package checksum;
- approval state and approving actor;
- installation timestamp;
- exact package identity on every Invocation.

The design leaves room for:

- publisher identity;
- cryptographic signature;
- source revision;
- CI/build identity;
- software bill of materials;
- vulnerability scan results.

An evidence-bearing Invocation must be able to state exactly which Tool
version and package checksum produced its result.

## Agent behavior

An Agent first discovers installed, approved Tools and reads their manifests.
It may select and configure a suitable Tool through an authorized Application
Operation. If no Tool performs the bounded operation, it may propose or
generate a Tool Package through the controlled development flow.

```text
intent
  -> inspect Application Operations and installed Tools
  -> use an existing approved Tool when suitable
  -> otherwise propose/generate a bounded Tool Package
  -> human review, test, install, and approve
  -> Application configuration pins the Tool version
  -> deterministic Run requests durable Invocations
```

The Agent reasons, configures, explains, and generates. Contexla and the
Application remain authoritative for execution, durable state, evidence,
permissions, and business conclusions.

## Operations and support

The Operations Console should eventually show, without exposing payloads or
secrets:

- installed Tool identities, versions, checksums, status, and worker profile;
- Tool Worker readiness and advertised features;
- pending/running/failed/timed-out Invocations;
- normalized error codes and affected Application Instance/Run;
- package preparation/cache failures;
- queue depth and oldest waiting Invocation.

Support bundles may include the same bounded metadata but never Tool source,
credentials, Invocation payloads, unrestricted stderr, or Artifact contents.

## Non-goals for v1

V1 does not require:

- a Tool marketplace;
- autonomous production installation of generated code;
- arbitrary operating-system dependency installation;
- a separate service or permanent container per Tool;
- a generic visual workflow builder;
- automatic replacement of pinned Tool versions;
- strong sandboxing of unreviewed code;
- multiple interchangeable implementations behind a separate abstract entity.

Add those only when a real customer requirement cannot be satisfied through
reviewed Tool Packages and the existing Application/Run model.

## Worked example: PDF accessibility

An Accessibility Application receives one PDF Artifact and requires metadata,
structure, and image-text analysis.

```text
Application Operation: accessibility.check_pdf
        -> Application Run
        -> three pending Tool Invocations and Oban jobs
             1. validate PDF metadata
             2. validate PDF structure tree
             3. OCR PDF images
        -> document_tools workers execute them
        -> each Invocation validates and stores its own result/Artifacts
        -> Application aggregates results
        -> Application persists Findings and Evidence
        -> Run completes
```

The metadata Tool may use one PDF library while the OCR Tool uses another
PDFium version and OCR dependencies. Their environments do not modify one
another. Neither Tool decides the Application's final policy result.

## Implemented migration

The repository completed a bounded migration rather than retaining parallel
public runtimes:

1. introduced the Tool SDK manifest and Tool definition;
2. merged contract and implementation metadata into one Tool record;
3. replaced Capability Invocation with durable Tool Invocation;
4. replaced binding resolution with explicit Tool ID/version in Application
   configuration or operation input;
5. converted the native Composer dependency proof into one bundled Tool;
6. updated Application Operation requirements to reference exact Tools where
   needed;
7. updated the Operations Console and support projections;
8. removed the old Capability/Processor runtime after data/code migration;
9. will add an external child-process Runner only when the first reviewed external
   Tool requires it;
10. will add Python environment preparation only with that concrete Tool proof.

Do not maintain both architectures as permanent public contracts.
