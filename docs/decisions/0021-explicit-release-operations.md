# 0021: Explicit release installation and operations

- Status: Accepted
- Date: 2026-11-21

## Context

Development used Mix tasks for platform migrations, package migrations, and
administrator bootstrap. Mix is not included in a production BEAM release, and
starting the web process must not mutate database schemas implicitly. An
on-premise installation also needs bounded health checks and a coordinated
backup boundary for PostgreSQL and Artifact storage.

## Decision

The platform exposes release-safe functions invoked through `bin/contexla eval`:

- `Contexla.Release.migrate_all/0` prepares Artifact storage, applies platform
  migrations, then runs registered Application migrations;
- `Contexla.Release.bootstrap_admin/0` consumes explicit environment credentials
  and preserves the one-time bootstrap rule;
- `Contexla.Release.diagnostics/0` starts the non-serving runtime, checks bounded
  dependencies including Oban, emits JSON, and fails the command when readiness
  is incomplete.

The serving process never migrates or bootstraps implicitly. Public liveness and
readiness endpoints expose only bounded status. PostgreSQL and Artifact storage
are backed up and restored as one installation boundary.

The base release contains zero concrete Application or Integration packages.
Early customer distributions register a small curated set from external,
checksum-verified package directories.

## Consequences

- installation and upgrade order is explicit and automatable;
- release commands work without Mix or platform source code;
- orchestrators can distinguish process liveness from dependency readiness;
- backup procedures cannot incorrectly treat PostgreSQL as the whole product;
- package registration remains a deployment concern rather than a marketplace;
- automated rollback remains constrained by migration compatibility and must be
  documented per release.
