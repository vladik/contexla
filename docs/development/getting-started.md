# Getting started

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
capabilities/sdk/                         Capability contract SDK
capabilities/bundled/                     first-party Capability definitions
processors/native/                        trusted native Processors
integrations/sdk/                        Integration package contract
integrations/drupal/                     first bundled Integration
docs/                                    product and architecture source of truth
```

Each package is a separate Mix project. The platform includes the bundled
packages through path dependencies. This follows the package-versus-instance
pattern without making dynamic package installation part of the first slice.

## Start PostgreSQL

Start Docker Desktop or another compatible Docker daemon, then from the
repository root run:

```powershell
docker compose up -d postgres
```

The checked-in `contexla/contexla_dev` credential is only for the loopback-bound
development database. It is exposed on port `55433` by default to avoid
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

Open `http://localhost:4000`.

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

Set-Location ../../integrations/sdk
mix test

Set-Location ../drupal
mix test

Set-Location ../../capabilities/sdk
mix test

Set-Location ../bundled
mix test

Set-Location ../../processors/native
mix test
```

The combined package registry can be smoke-checked without PostgreSQL:

```powershell
Set-Location ../../platform
mix run --no-start -e '{:ok, pid} = Contexla.Packages.Registry.start_link(); IO.inspect({Contexla.Packages.Registry.applications(), Contexla.Packages.Registry.integrations()}); GenServer.stop(pid)'
```

The platform also starts `Contexla.CapabilityRuntime.Registry`. Bundled
Capability and Processor definitions are code-authoritative and are mirrored
to PostgreSQL lazily before invocation. Applications invoke contracts through
`Contexla.Capabilities`; they must not call Processor modules directly.

The platform's generated `mix test` alias provisions the test database before
running ExUnit, so the complete platform suite intentionally requires the
database service.

