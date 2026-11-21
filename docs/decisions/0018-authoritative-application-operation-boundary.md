# Authoritative Application Operation boundary

Status: Accepted
Date: 2026-11-21

## Context

Application callbacks were reachable through a GET route using any supplied
Operation ID. The platform did not verify declaration, input, required
Capabilities, or approval, and did not retain an invocation record. Application
UI could also call domain execution directly. That boundary would be unsafe for
state-changing commands and impossible to expose consistently to future agents.

## Decision

All Application Operation execution passes through the platform-owned
`Contexla.ApplicationOperations` service.

Before calling Application code, it verifies:

1. authenticated Instance access and exact package version;
2. an Operation declared by that Application version;
3. command/read transport semantics;
4. structured input, including rejection of undeclared fields when requested;
5. executable bindings for required Capabilities;
6. explicit approval from the authenticated actor when required.

Commands use POST or a trusted runtime service. GET is allowed only for
Operations declared as read-only. Successful execution, controlled failure,
and download results complete a platform-owned Operation Invocation. The record
stores package and Operation identity, actor and approver, bounded schema-driven
input, status, safe error code, optional Run identity, and small result metadata.
It never stores complete reports or arbitrary callback results.

In this first version approval is supplied synchronously by the authenticated
human action and attributed to that user. A future Agent approval inbox may add
a pending approval workflow without bypassing this service.

## Consequences

- UI, API, schedules, and agents share one enforceable execution boundary.
- Application callbacks cannot be selected with undeclared identifiers.
- State-changing commands are not executed through GET.
- Operation Invocation and Application Run remain distinct and can be linked.
- Sensitive input properties must be marked in the Operation schema; only
  declared fields are projected into audit storage.
- Retry idempotency keys and asynchronous approval workflows remain separate
  foundation increments.
