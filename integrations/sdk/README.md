# Contexla Integration SDK

This package defines the platform-facing contract for independently compiled,
trusted Integration packages.

An Integration package can contribute:

- low-level Clients for protocols, authentication, pagination, rate limits, and
  source-native errors;
- Adapters that implement stable Application-facing contracts and translate
  external-system data into structures an Application understands;
- Connection types and optional support for an external Connector when native
  collection or events are required.

The concepts are deliberately separate:

```text
optional external Connector
        -> Client
        -> Adapter implementing an Application-facing contract
        -> Application
```

An Adapter is not merely an HTTP wrapper and must not own unrelated Application
business decisions. Clients may be shared widely. Adapters are shared only when
multiple Applications genuinely consume the same stable contract; otherwise
each Application may use a thin domain-specific Adapter over the same Client.

The platform discovers Integration definitions and Adapters through this SDK.
It must not depend on a concrete Integration package. See
[`docs/architecture/concepts.md`](../../docs/architecture/concepts.md) and
[`docs/product/business-intent-and-priorities.md`](../../docs/product/business-intent-and-priorities.md).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `contexla_integration_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:contexla_integration_sdk, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/contexla_integration_sdk>.
