# Bundled Applications own domain code while the release owns infrastructure wiring

Status: Superseded by ADR 0011
Date: 2026-11-19

## Context

Digital Estate Assessment must own its domain without making dynamic Application
installation, arbitrary migrations, or a large shared execution framework the
critical path to the first paid assessment. The current repository uses separate
Mix projects, with the Phoenix platform depending on bundled Application
packages.

## Decision

For the first bundled vertical slice:

- `contexla_estate` owns its Ecto schemas, deterministic rules, operation
  definition, and thin Oban worker;
- the platform owns the configured Ecto Repo, authentication scope, Artifact
  storage, package registries, Capability runtime, and the infrastructure
  executor used by that worker;
- the worker resolves its configured executor at runtime, avoiding a reverse
  compile dependency from the Application package to the platform;
- estate tables use the `estate_` prefix and remain semantically Application-
  owned;
- migrations for this bundled Application currently ship in the platform
  release migration path so installation and upgrade remain one controlled
  operation;
- arbitrary uploaded Applications and package-provided migration execution
  remain deferred.

## Consequences

- The Application boundary is real and independently testable without requiring
  a dynamic package marketplace.
- Infrastructure authorization and reliability remain centralized.
- Physical migration placement is temporarily release-owned even though table
  semantics and schemas are Application-owned.
- If a second Application demonstrates the same execution needs, extract the
  executor contract and migration lifecycle based on that evidence.
- Do not move Assessment rules or tables into generic platform records merely
  to remove this explicit bridge.

## Supersession

Implementation demonstrated that the infrastructure executor, platform-owned
migrations, concrete routes, and compile-time package dependency made the host
aware of Application semantics. ADR 0011 replaces this bridge with the same
independent-package architecture proven by WakeCanvas.
