# Contexla.ApplicationSDK

The Contexla Application SDK is the only supported compile-time contract between
the platform and an independently developed trusted Application.

An Application declares its identity, configuration schema, operations, Adapter
requirements, PostgreSQL schema, and UI surfaces. It may own Ecto schemas,
migrations, Oban workers, LiveViews, reports, assets, and supervised runtime code.
It accesses shared platform facilities through `Contexla.ApplicationSDK.Runtime`
instead of depending on platform modules.

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
