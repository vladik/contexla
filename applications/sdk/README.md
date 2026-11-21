# Contexla.ApplicationSDK

The Contexla Application SDK is the only supported compile-time contract between
the platform and an independently developed trusted Application.

An Application declares its identity, configuration schema, operations, Adapter
requirements, PostgreSQL schema, and UI surfaces. It may own Ecto schemas,
migrations, Oban workers, LiveViews, reports, assets, and supervised runtime code.
It accesses shared platform facilities through `Contexla.ApplicationSDK.Runtime`
instead of depending on platform modules.

`Runtime` exposes named functions for the supported host services: Instance
management, Artifacts and source import, Adapter lookup, Capability and
Operation invocation, durable job enqueueing, and the shared Ecto Repo used by
Application-owned schemas. Applications must not dynamically invoke platform
function names or depend on `Contexla.ApplicationServices`; adding or changing
a host service is an SDK contract change.

An Application Operation is a domain command exposed to the platform UI, API,
agents, and approved triggers. It may coordinate Application state and multiple
Capabilities; it is not a small reusable Capability and does not imply a generic
workflow graph. Invocations that require durability or auditability produce
Runs owned by the Application or shared runtime conventions.

Each Operation declares whether it is a state-changing `:command` or read-only
`:read`, its structured input schema, approval requirement, and required
Capabilities. Commands execute through POST or trusted runtime services; only
declared read Operations are callable through GET. Inputs may mark properties
with `"sensitive" => true` so invocation audit data stores a redacted value.

An Operation callback may return `{:ok, result, run_id: id}` to link the
platform-owned Operation Invocation to an Application-owned Run. Download
options may provide the same internal `run_id`; it is recorded but removed
before options reach the HTTP download response.

Each definition must declare a shared icon, exactly one `new` surface, exactly
one default `instance` surface, and exactly one Instance surface with
`kind: :settings`. The default surface is mounted for the canonical
`/applications/:instance_id` URL; it does not need to be named `index`. The
platform chooses the package, while the `new` surface owns setup and the
settings surface owns mutable Application-domain configuration.

## Create an Application

The starter creates a separate Mix project that depends on this SDK and the
route-free `contexla_ui` package. It does not register the generated package or
make it a platform dependency.

```powershell
mix contexla.application.new ..\my_application `
  --module Acme.MyApplication `
  --id com.acme.application.my-application `
  --name "My Application"
```

The generated surfaces demonstrate the required setup, canonical overview,
collection/list-detail, and Application settings patterns. Replace the starter
content with a focused business use case and keep domain behavior inside the
Application. See `docs/development/application-ui.md` in the repository for the
UI contract.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `contexla_application_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:contexla_application_sdk, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/contexla_application_sdk>.
