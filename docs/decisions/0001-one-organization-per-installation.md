# One organization per installation

Status: Accepted
Date: 2026-11-19

## Context

The initial customers are expected to prefer on-premise deployment and data
isolation. Organization/workspace multitenancy would add membership, isolation,
authorization, billing, and operational complexity before it supports revenue.

## Decision

One Contexla installation represents one organization. It may have multiple
users and Application Instances. Organizations requiring isolation run separate
installations.

## Consequences

- No organization or workspace selector is required initially.
- Authorization still applies between users and administrative functions.
- Data models must not casually assume future cross-tenant sharing.
- Introducing multitenancy later requires a new decision and migration design.

