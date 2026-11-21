# Capability and Processor runtime

This document is the implementation guide for Contexla's executable extension
model. The normative hierarchy is:

```text
Application
  -> Capability contract
  -> Capability Binding
  -> Processor implementation
  -> runtime Runner
  -> Capability Invocation
```

## Package boundaries

- `capabilities/sdk` defines implementation-neutral structs, validation, and
  package behaviours.
- `capabilities/bundled` contains trusted first-party Capability contracts.
- `processors/native` contains trusted BEAM Processor implementations.
- Future Python/CLI packages belong under `processors/`, not `capabilities/`.
- `platform/lib/contexla/capability_runtime` owns discovery, schema validation,
  and runtime-specific Runners.
- `platform/lib/contexla/capabilities` owns the PostgreSQL catalog, Bindings,
  Invocations, resolution, and authenticated public service API.

## Authority and persistence

Bundled package definitions in the release are authoritative. On catalog sync,
Contexla mirrors each Capability and Processor version into PostgreSQL. A
matching identity/version with a different digest is rejected; immutable
version identity must not silently change.

PostgreSQL owns operational state:

```text
capabilities             mirrored contract versions
processors               mirrored implementation versions
capability_bindings      selected implementation/config/permissions by scope
capability_invocations   execution provenance and result
```

External Processor package source or binaries should be retained as immutable
Artifacts and referenced by the Processor record. Large invocation data should
also use Artifacts when the vertical slice requires it.

## Binding resolution

For an Application Instance, the resolver checks:

1. Instance Binding (`scope_key = Application Instance id`);
2. Application Binding (`scope_key = Application definition id`);
3. Platform Binding (`scope_key = platform`).

The first active Binding with an active Processor wins. Every permission
requested by the Processor must be present in the Binding's granted permissions.
Bundled default Processors create a Platform Binding only when no Platform
choice exists; catalog sync never overwrites an administrator's choice.

## Invocation path

`Contexla.Capabilities.invoke/5` is the public authenticated boundary:

1. synchronize bundled definitions;
2. resolve the exact active Capability contract;
3. validate structured input;
4. resolve the scoped Binding and Processor;
5. verify granted permissions;
6. create a running Invocation with actor and Application Instance;
7. dispatch to the runtime Runner with timeout and approved configuration;
8. validate structured output;
9. complete the Invocation with output or a normalized error.

Application services and Oban workers use this boundary. They do not call
Processor entrypoints directly. Oban can make Application Runs durable, but it
does not replace Capability Invocation provenance.

## Current implementation and deliberate limits

The first proof includes:

- one bundled contract: `com.contexla.dependencies.parse-composer` version `2`;
- one native Processor: `com.contexla.processor.composer.native` version
  `0.1.0`;
- a small JSON Schema subset for object, array, string, integer, number,
  boolean, null, required fields, properties, and array items;
- native Task execution with a timeout;
- platform default Binding and Invocation persistence.

It does not yet include a Python Runner, dependency-environment builder,
processor upload/approval UI, arbitrary dynamic package installation, or Oban-
backed asynchronous Capability execution. Add those only when the assessment
vertical slice needs them.

## Agent extension rule

An agent distinguishes two gaps:

- **Missing Processor:** the Capability contract already expresses the needed
  operation. Generate/test a Processor and bind it at the narrowest scope.
- **Missing Capability:** no existing contract has the required semantic
  meaning. Define and review a contract, then provide a Processor.

Generated code never receives authority merely because an agent created it. It
must pass package validation and tests, use an isolated environment where
applicable, be explicitly approved, receive bounded permissions, and execute
through the same invocation path as human-authored Processors.
