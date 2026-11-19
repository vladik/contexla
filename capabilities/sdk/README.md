# Contexla Capability SDK

This package defines implementation-neutral Capability contracts and Processor
package contracts.

- `Capability` describes what an operation means: identity, contract version,
  I/O/error schemas, permissions, determinism, side effects, and idempotency.
- `Processor` describes one implementation: runtime, entrypoint, dependency
  specification, configuration, permissions, limits, and version.
- `Requirement` lets Applications depend on a Capability contract without
  depending on a Processor.

Keep executable implementation code out of this project. See
[`docs/architecture/capability-runtime.md`](../../docs/architecture/capability-runtime.md).
