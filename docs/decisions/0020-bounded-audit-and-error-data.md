# 0020: Bound audit data and persisted failures

- Status: Accepted
- Date: 2026-11-21

## Context

Contexla executes customer-supplied evidence and will eventually handle
encrypted credentials. Early Capability Invocations stored full validated input
and output, and some failure paths serialized arbitrary terms with `inspect/1`.
Validation alone does not make those values safe for durable audit storage or
user display. The current platform also lacked a common record for lifecycle
actions such as Instance configuration and source import.

## Decision

Capability and Operation contracts control their audit projection. Declared
schema properties marked `sensitive` are replaced with `[REDACTED]` before an
Invocation is persisted. Execution still receives the original validated value.

Failures crossing persistence, API, or UI boundaries use bounded codes from
`Contexla.ApplicationSDK.Error`; arbitrary strings, exceptions, changesets, and
nested terms are not copied into those boundaries.

Because audit projection is part of a Capability's observable contract, the
Composer dependency Capability advances to contract version `2` and its native
Processor to `0.2.0`; the existing version is not silently redefined.

The platform owns an append-only `audit_events` table for security and
lifecycle actions not already represented by a domain Run or Invocation. The
initial events cover Application Instance creation, settings/configuration
updates, and source snapshot import. Event metadata records identities and
changed field names, not configuration values or secrets. A database-assigned
monotonic sequence orders events; timestamps describe time but are not treated
as a unique ordering key.

## Consequences

- audit history is useful without becoming a second store of sensitive input;
- Applications and the platform share one safe error-code convention;
- source imports and Instance mutations record actor-attributed lifecycle data;
- a future audit UI can read stable records without defining a new event model;
- internal diagnostic detail requires controlled logging/observability rather
  than leaking through persisted errors;
- new lifecycle events are added only for real actions, not speculative domains.
