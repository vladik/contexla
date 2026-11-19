# Trusted OTP extensions use controlled packages

Status: Accepted
Date: 2026-11-19

## Context

Applications and integrations may contain OTP code, migrations, workers, and
privileged access. Arbitrary runtime upload of such code creates substantial
operational and security risk.

## Decision

Trusted OTP Applications and Integration Packages use controlled build and
release packaging with identity, version, checksums, compatibility validation,
and an explicit installation lifecycle. The first Application and Drupal
integration are bundled with the release.

## Consequences

- An Application Definition/SDK contract is established before dynamic
  installation is implemented.
- Arbitrary uploaded Applications and migrations are not on the revenue-critical
  path.
- Package provenance and compatibility are platform concerns.
- Small isolated Capabilities follow a different trust and execution model.

