# Python Processors run out of process in isolated environments

Status: Superseded by [ADR 0024](0024-unified-tool-execution-model.md)
Date: 2026-11-19

## Context

Python provides specialist libraries and a practical target for agent-generated
implementations. A shared environment would cause dependency conflicts and make
generated code difficult to control. Capability is now the implementation-
independent operation contract; executable Python code is a Processor.

## Decision

Each Python Processor owns a versioned manifest, source, dependency lock, tests,
and isolated environment. It declares which Capability contract it implements.
Contexla invokes it out of process through a Capability Binding using structured
input/output, timeout, resource, permission, validation, and approval controls.

## Consequences

- Python code does not execute inside the BEAM VM.
- One Processor cannot depend on another's mutable environment.
- Process isolation is sufficient for the first proof; stronger sandboxing may
  be added according to threat model and customer policy.
- Generated Processors are untrusted until validated and approved.
- Applications remain coupled to Capability contracts, not Python packages.
- The deterministic assessment is built before this proof is introduced.
