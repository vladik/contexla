# 0022: Administrator operations visibility

- Status: Accepted
- Date: 2026-11-21

## Context

Contexla persists Operation Invocations, Capability Invocations, Oban jobs, and
append-only audit events, but an installation administrator otherwise needs
database access to correlate them during a support incident. Application Runs
and evidence are domain-owned, while infrastructure health and shared execution
boundaries are platform-owned. Exposing raw payloads or exception terms in a
general console would create an unnecessary secret and content disclosure path.

## Decision

The platform provides an administrator-only, read-only Operations Console. It
projects bounded health checks, registered package state, recent shared-runtime
Invocations, safe error codes, recent Oban job metadata, and lifecycle audit
events. It links shared activity to the affected Application Instance but does
not interpret or copy Application-owned Run state.

The existing `admin` role represents the installation administrator in the
single-organization deployment model. There is no separate super-administrator
role. Authorization is enforced both at the router/LiveView boundary and in the
operational query service.

The projection excludes invocation payloads, job arguments, exception text,
credentials, and Artifact contents. Detailed logs remain in the deployment's
external log system. Liveness/readiness probes and process supervision remain
external monitoring inputs because the console cannot diagnose its own complete
outage.

## Consequences

- support can correlate failures without direct database access;
- shared runtime health remains separate from Application-domain diagnosis;
- regular users cannot inspect installation-wide activity;
- the console is not a replacement for uptime monitoring, centralized logs,
  alerts, or Application-specific Run views;
- future metrics and support-bundle work can extend this boundary without
  exposing arbitrary stored data.
