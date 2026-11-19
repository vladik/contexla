# Applications own their domains and workers

Status: Accepted
Date: 2026-11-19

## Context

A generic record/workflow schema would obscure domain meaning and couple all
solutions to one abstraction. OTP Applications provide strong in-process
boundaries without requiring microservices.

## Decision

Each substantial Application owns its domain services, tables, migrations,
workers, reports, and Application-specific integration contracts. The platform
owns only cross-Application infrastructure demonstrated to be shared.

## Consequences

- Digital Estate Assessment owns Resources, Relationships, Findings, and its
  assessment model.
- Shared Run, Artifact, Connection, and Application Instance conventions may be
  platform-owned, but must not absorb Application domain data.
- Cross-Application reuse happens through explicit contracts and services, not
  direct writes to another Application's tables.

