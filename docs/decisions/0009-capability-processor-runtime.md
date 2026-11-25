# Separate Capability contracts from Processor implementations

Status: Superseded by [ADR 0024](0024-unified-tool-execution-model.md)
Date: 2026-11-19

## Context

Calling executable packages “Capabilities” conflates the semantic operation an
Application needs with one language-specific implementation. Contexla must be
able to replace implementations, add customer-specific implementations, and
retain exact execution provenance without rewriting Applications.

## Decision

Use this hierarchy:

```text
Application -> Capability -> Capability Binding -> Processor -> Runner
```

- A Capability is an immutable, versioned semantic contract with I/O/error
  schemas, permissions, determinism, side effects, and idempotency.
- A Processor is an immutable, versioned implementation with runtime,
  entrypoint, package/dependencies, configuration, requested permissions,
  timeout, and resource limits.
- A Capability Binding selects and configures a Processor at Instance,
  Application, or Platform scope, in that resolution order.
- A Capability Invocation records the resolved contract, Processor, Binding,
  actor, input, output/error, and status.
- A Runner is internal platform infrastructure for a Processor runtime.
- Bundled code definitions are authoritative; PostgreSQL mirrors definitions
  for discovery and stores Bindings and Invocation history.
- Same-version definition drift is rejected. A changed contract or Processor
  requires a new version.

Applications request a Capability identity and contract version and must not
call Processor entrypoints directly.

## Consequences

- A v1 Capability may have only one Processor, but the concepts remain separate.
- Native Elixir, isolated Python, CLI, and HTTP implementations can satisfy the
  same Application dependency.
- Customer-specific Processors can begin at Instance scope and later be
  promoted after review and proven reuse.
- The runtime must validate input and output, enforce granted permissions, bound
  execution, and preserve provenance.
- Authentication, Artifact storage, Oban behavior, source package admission,
  and supervision remain infrastructure rather than artificial Capabilities.
