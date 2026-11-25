# Unify executable extensions as Tools

Status: Accepted
Date: 2026-11-23

## Context

Contexla originally separated a small executable operation into a Capability
contract, one or more Processor implementations, a scoped Binding, a runtime
Runner, and a Capability Invocation. The repository proved that model with a
native Composer dependency operation.

During design of AI-assisted extension and multi-runtime execution, the split
created indirection without a demonstrated need for transparent interchangeable
implementations. It also made the Agent extension lifecycle difficult to
explain: a generated Processor was unusable without a pre-existing Capability,
while a newly generated Capability still required a Processor and Binding.

The actual requirement is simpler. Contexla needs small versioned executable
units with machine-readable contracts, implementation/runtime metadata,
dependency isolation, explicit installation, durable execution provenance, and
safe use by Applications and Agents.

## Decision

Contexla adopts **Tool** as the single formal executable-extension concept.

> A Tool is a small, versioned executable unit that performs one bounded
> operation.

A Tool owns its identity, version, purpose, input/output schemas,
implementation, runtime, entrypoint, dependencies, permissions, limits, tests,
and worker compatibility requirements.

The target execution model is:

```text
Application or Agent
        -> durable Tool Invocation
        -> Oban Tool job
        -> compatible Tool Worker
        -> Tool
        -> validated result and Artifacts
```

Applications explicitly pin the Tool ID and version they use. New versions do
not replace existing configuration automatically. Applications own business
orchestration and domain interpretation; Tools do not write Application state
or schedule their own work.

AI-generated Tools initially use a reviewed software-development and deployment
flow. Production Agents do not autonomously install or execute generated code.
Python is the expected first generated runtime, with one isolated virtual
environment per Tool version. Strong sandboxing is deferred.

The normative technical contract is documented in
`docs/architecture/tool-runtime.md`.

## Superseded decisions

This decision supersedes the public architecture in:

- ADR 0007, **Python Processors run out of process in isolated environments**;
- ADR 0009, **Separate Capability contracts from Processor implementations**.

Their requirements for structured I/O, dependency isolation, version
immutability, validation, approval, bounded permissions, and auditable
execution remain applicable to Tools.

## Consequences

- Capability, Processor, Capability Binding, and Capability Invocation are no
  longer target product or SDK concepts.
- Tool and Tool Invocation become the formal registry/runtime concepts.
- A Tool Package is a distributable representation, not a separate operation
  abstraction.
- The existing Capability/Processor code becomes transitional implementation
  that must be migrated rather than expanded.
- Applications and Agents have a shorter, more understandable extension path.
- Transparent implementation swapping is not provided through a separate
  abstract contract. Applications explicitly change their pinned Tool version.
- Reviewed custom Tool development becomes a practical agency service without
  requiring autonomous production code installation.
- Multi-machine execution uses Contexla runtime roles and Oban queues rather
  than permanent per-Tool services.

## Non-decision

This ADR does not choose a marketplace, sandbox provider, remote execution
service, generic workflow engine, or autonomous package installer. Those require
separate evidence and decisions.
