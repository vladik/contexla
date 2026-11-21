# Explicit package lifecycle and exact Instance version pinning

Status: Accepted
Date: 2026-11-21

## Context

Application discovery originally ran Application-owned migrations as a side
effect of registry startup and loaded external OTP Applications without starting
their supervision trees. Application Instances recorded a package version, but
surface and service resolution used only the Application ID. Those behaviors
made startup mutate the database and allowed an Instance to silently execute
against different code.

## Decision

Package lifecycle stages are distinct:

1. package build validates the manifest against the compiled definition;
2. controlled installation loads and validates package code without starting
   its supervision tree, then runs registered Application migrations explicitly;
3. runtime discovery loads, starts, validates, and registers external OTP
   Applications without database mutation;
4. Instance access requires its pinned version to exactly match the one active
   version registered for its Application ID.

The initial runtime intentionally supports one active version per Application
ID. Multi-version execution and automated Instance upgrades are not implied.

## Consequences

- Application supervision trees actually participate in runtime execution.
- Server startup is read-only with respect to schema migrations.
- Deployment automation must run `mix contexla.packages.migrate` after platform
  migrations and before accepting traffic.
- Package upgrades that change a version make existing Instances unavailable
  until an explicit upgrade policy migrates or repins them.
- A future production installer must preserve the same staged lifecycle.
