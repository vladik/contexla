# Getting started

> Executable extensions use the unified Tool model defined by
> [Tool architecture and runtime](../architecture/tool-runtime.md).

## Prerequisites

- Elixir 1.20 and Erlang/OTP 29;
- Docker with Compose for the development PostgreSQL service;
- Git;
- Node.js is not required for the generated Phoenix asset toolchain.

The initial skeleton was generated with Phoenix installer 1.8.9.

## Repository projects

```text
platform/                                Phoenix release and shared platform
applications/sdk/                        Application package contract
applications/digital_estate_assessment/  first bundled Application
applications/content_integrity_monitor/  active portfolio Application proof
tools/sdk/                               Tool definition and package contract
tools/bundled/                           trusted bundled Tools
integrations/sdk/                        Integration package contract
integrations/drupal/                     first bundled Integration
docs/                                    product and architecture source of truth
```

Each package is a separate Mix project. The platform depends only on the SDKs;
it does not compile against Digital Estate Assessment or Drupal. Applications
and Integrations are compiled independently and registered from their BEAM paths
during development.

## Start PostgreSQL

Start Docker Desktop or another compatible Docker daemon, then from the
repository root run:

```powershell
docker compose up -d postgres
```

The checked-in `contexla/contexla_dev` credential is only for the loopback-bound
development database. It is exposed on port `15432` by default to avoid
collisions with other local projects; set `POSTGRES_PORT` to override it.
Production uses `DATABASE_URL` and externally managed secrets.

Development Artifacts are stored under `platform/.tmp/artifacts`. Production
requires `CONTEXLA_ARTIFACTS_PATH` to point to durable, access-controlled
storage owned by the Contexla service account.

## Set up the platform

```powershell
Set-Location platform
mix deps.get
mix ecto.setup
mix assets.setup
mix assets.build
mix test
mix phx.server
```

Open `http://localhost:4100` when using the source-linked development launcher.

Database setup includes platform and Oban tables only. Application package
discovery never changes the database. After registering a curated package set,
run `mix contexla.packages.migrate` explicitly to apply migrations into each
Application-owned schema. The source-linked development launcher performs this
step before starting the server. In tests, Oban uses manual mode.

To compile the Assessment and Drupal packages independently and start the
platform with them source-linked through the runtime registry, run from the
repository root:

```powershell
.\scripts\dev-platform.ps1
```

Starting `mix phx.server` directly under `platform/` intentionally boots with
zero concrete Applications installed.

The source-linked development launcher defaults to port `4100` so it can run
alongside another local Phoenix project on port `4000`. Override it when needed:

```powershell
.\scripts\dev-platform.ps1 -Port 4200
```

This changes only the Contexla listener started by the script.

## Run the Content Integrity demonstration

Start the Application-owned external HTTP source simulator in one terminal:

```powershell
Set-Location applications/content_integrity_monitor
$env:MIX_ENV = "test"
mix deps.get
mix run --no-halt test/simulators/run_external_http_source.exs
```

The simulator is acceptance-test infrastructure owned by Content Integrity
Monitor. It is compiled only in the test environment, is not a Connector, and
is excluded from the production Application package.

Start PostgreSQL as described above, then run the independently registered
Content Integrity Application in another terminal:

```powershell
Set-Location C:\Repos\contexla
.\scripts\dev-integrity.ps1
```

Open `http://localhost:4100`, create a Content Integrity Monitor Instance,
create the demonstration Monitor from its Overview, and start a Run. The demo
defaults to an overdue website credential and a missing search duration. Its
mode can be changed without restarting:

```powershell
Invoke-RestMethod -Method Post http://localhost:4205/mode/pending
Invoke-RestMethod -Method Post http://localhost:4205/mode/overdue
Invoke-RestMethod -Method Post http://localhost:4205/mode/unavailable
```

For a repeatable non-UI proof, leave the synthetic source running and execute
the same Application Operations through a script from another terminal:

```powershell
Set-Location platform
$application = (Resolve-Path ..\applications\content_integrity_monitor).Path
$env:CONTEXLA_APPLICATION_PACKAGES = "$application\_build\dev\lib\content_integrity_monitor\ebin|Contexla.Applications.ContentIntegrityMonitor.Package"
mix run ..\scripts\run-local-integrity-proof.exs
```

The script reuses a named local Instance, runs `overdue`, `pending`, and
`unavailable` modes, waits for the Oban and Tool Invocation path, and prints
Run summaries plus evidence identities. It requires an existing administrator
and current platform/Application migrations. It is synthetic development
evidence, not buyer validation.

## Bootstrap the administrator

Contexla does not expose public account registration and does not ship a shared
default password. Create the first administrator once, using a unique temporary
password supplied through the process environment:

```powershell
$env:CONTEXLA_ADMIN_EMAIL = "admin@example.com"
$env:CONTEXLA_ADMIN_PASSWORD = "replace-with-a-unique-temporary-password"
mix contexla.admin.bootstrap
Remove-Item Env:CONTEXLA_ADMIN_PASSWORD
```

The task refuses to run after any user exists. The administrator is redirected
to account settings and must change the bootstrap password before accessing
platform routes.

## Test package projects independently

```powershell
Set-Location applications/sdk
mix test

Set-Location ../digital_estate_assessment
mix test

Set-Location ../content_integrity_monitor
mix test

Set-Location ../../integrations/sdk
mix test

Set-Location ../drupal
mix test

Set-Location ../../tools/sdk
mix test

Set-Location ../bundled
mix test
```

`CONTEXLA_APPLICATION_PACKAGES` and `CONTEXLA_INTEGRATION_PACKAGES` accept
semicolon-separated `EBIN_PATH|Entry.Module` registrations. The development
script sets these variables; production installation will populate equivalent
validated package registrations from the package catalog.

The platform also starts `Contexla.Platform.ToolRuntime.Registry`. Bundled Tool
definitions are code-authoritative and are mirrored to PostgreSQL before
invocation. Applications request exact Tool versions through the typed
Application SDK; they must not call Tool entrypoints directly.

The platform's generated `mix test` alias provisions the test database before
running ExUnit, so the complete platform suite intentionally requires the
database service.

## Continuous integration

`.github/workflows/ci.yml` compiles, format-checks, and tests every independent
Mix project. The platform job runs against PostgreSQL 17 and also builds the
browser assets; the Digital Estate Assessment job builds its trusted
`.contexla-app` archive. Keeping these as separate jobs protects the package
boundaries: the platform must pass without adding a concrete Application or
Integration dependency.

After those jobs pass, CI builds a production platform release with zero
concrete packages, migrates an empty PostgreSQL database, bootstraps an initial
administrator, runs release diagnostics, starts the release, and verifies both
health endpoints.

## Local Drupal collector proof

The read-only collector spike lives under `connectors/drupal_snapshot/`. Its
synthetic college fixture is intentionally separate from the Drupal Integration
package: the collector acquires source-native evidence, while the Integration
validates and normalizes it.

Generated DDEV database checkpoints and snapshot ZIPs are local development
state and are not committed. After producing a clean and a seeded ZIP, the full
local proof can be run without starting a web listener:

```powershell
Set-Location platform

$env:CONTEXLA_APPLICATION_PACKAGES = `
  "<assessment-ebin>|Contexla.Applications.DigitalEstateAssessment.Package"
$env:CONTEXLA_INTEGRATION_PACKAGES = `
  "<drupal-ebin>|Contexla.Integrations.Drupal.Package"
$env:CONTEXLA_BASELINE_SNAPSHOT = "<clean-snapshot.zip>"
$env:CONTEXLA_SEEDED_SNAPSHOT = "<seeded-snapshot.zip>"
$env:CONTEXLA_PROOF_REPORT = "<report-output.json>"

mix run ..\scripts\run-local-drupal-proof.exs
```

The runner reuses the named local Assessment Instance, imports immutable
Artifacts by hash, executes two auditable Runs, and writes the seeded Run's JSON
report. It requires an existing administrator because the Run and artifacts
must have a real local actor. This is a development proof, not a replacement for
real college evidence or customer acceptance.

