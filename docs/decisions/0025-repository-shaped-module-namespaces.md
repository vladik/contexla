# Use repository-shaped module namespaces

Status: Accepted
Date: 2026-11-24

## Context

Contexla is a modular repository containing independently compiled
Applications, Tools, Integrations, Connectors, shared SDKs, platform code, and
Application-owned testing infrastructure. Early Content Integrity code used
the short `Contexla.Integrity` namespace, which concealed that the module
belonged to a specific installable Application. Generic test locations such as
`support` also made runnable simulators difficult to classify.

Elixir does not enforce a relationship between module names and file paths.
Without a project convention, developers and coding agents must repeatedly
infer ownership and can place package-specific code in shared or misleading
locations.

## Decision

Contexla adopts repository-shaped namespaces:

```text
Contexla.<PackageCategory>.<PackageName>.<Folder>...<ModuleName>
```

Top-level package categories retain their repository spelling, including
pluralization. For example:

```text
applications/content_integrity_monitor/test/simulators/external_http_source.ex

Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource
```

The `lib` production compilation root is omitted. Test modules explicitly
include `Test`. Application-owned fixtures, simulators, and acceptance
infrastructure remain within the owning Application's test tree and use folders
that state their purpose.

The complete convention and examples are defined in
`docs/development/module-naming.md`.

## Consequences

- Module names are longer but expose package ownership and placement.
- File navigation and agent-generated code become predictable.
- Different packages are less likely to create ambiguous or colliding modules.
- Generators and new code must follow the convention.
- Existing short namespaces are transitional and require controlled refactoring.
- Module renaming does not by itself rename database schemas, tables, public
  package IDs, OTP application atoms, or URLs.
