# Applications are independently compiled and installed through the SDK

Status: Accepted
Date: 2026-11-19

## Context

Contexla must support a growing portfolio of Applications without rebuilding or
teaching the platform about every business domain. WakeCanvas already proves a
trusted OTP package model in which the host knows only an SDK, a manifest, stable
routes, and lifecycle callbacks.

The first Assessment slice incorrectly placed its executor, UI, reports, routes,
tests, and migrations in the platform and added the concrete Application as a
platform dependency. That made the package boundary descriptive rather than real.

## Decision

- The platform depends only on `contexla_application_sdk`, not concrete
  Applications.
- Every Application is an independently buildable trusted OTP package.
- An Application owns its domain services, schemas, migrations, workers,
  execution, reports, LiveViews, and browser assets.
- The SDK definition declares stable identity, operations, UI surfaces,
  configuration, Adapter requirements, and an optional PostgreSQL schema.
- The platform owns generic routes and dynamically resolves surface modules
  through the runtime registry.
- Platform facilities are exposed through bounded SDK runtime services; an
  Application does not compile against platform modules.
- Each Application migrates one owned PostgreSQL schema. Multiple Instances
  share its tables and are separated by `application_instance_id`.
- Package code is trusted native code. Installation validates identity and
  compatibility and activates code only during controlled startup/restart.
- The platform must boot and remain usable with zero Applications installed.

## Consequences

- Digital Estate Assessment can be built and tested without the platform source.
- Adding or upgrading an Application does not modify platform routes, contexts,
  migrations, or assets.
- Package and database rollback remain separate concerns.
- SDK compatibility, module collision checks, archive validation, and migration
  failure handling become explicit platform responsibilities.
- Source-linked registration proves the boundary first; the distributable archive
  installer must use the same registry and lifecycle rather than introduce a
  second execution path.
