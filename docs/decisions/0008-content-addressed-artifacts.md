# Immutable content-addressed Artifact storage

Status: Accepted
Date: 2026-11-19

## Context

Assessment conclusions must remain traceable to the exact source package that
was validated. User-supplied filenames are not stable identities and must not
control filesystem paths.

## Decision

Contexla stores validated files under a SHA-256-derived storage key and records
immutable Artifact metadata in PostgreSQL. The source hash and size are verified
again while copying into managed storage. Application Instances reference
Artifacts by database identity; original filenames are display metadata only.

The initial implementation uses durable local filesystem storage configured by
`CONTEXLA_ARTIFACTS_PATH`. A future object-storage backend must preserve the same
identity, immutability, provenance, and verification contract.

## Consequences

- Identical bytes can share one physical content-addressed blob while retaining
  Instance-specific Artifact records.
- Invalid packages are not recorded as Artifacts.
- Database backup alone is insufficient; Artifact storage and PostgreSQL require
  coordinated backup and retention.
- Storage cleanup must distinguish unreferenced blobs from referenced Evidence.
- ZIP contents are validated in memory and never executed or extracted into the
  application filesystem.
