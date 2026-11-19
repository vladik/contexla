# Proof-driven roadmap

Contexla should grow through proofs. Each phase answers one important question
and leaves behind something usable.

## Current implementation status

As of 2026-11-19, the repository proves:

- the Phoenix/PostgreSQL platform boots against a repository-local database;
- the bundled Digital Estate Assessment Application and Drupal Integration are
  discovered and contract-validated;
- an administrator can be bootstrapped without public registration or a shared
  default password;
- bootstrap credentials must be replaced before platform access;
- a validated, version-pinned Application Instance can be persisted;
- a Drupal snapshot ZIP can be security-checked, contract-validated, retained in
  content-addressed storage, and associated with an Instance as an immutable
  Artifact.
- bundled Capability and Processor packages are separately contract-validated;
- PostgreSQL mirrors Capability contracts and Processor versions, resolves
  scoped Bindings, validates I/O, and records auditable native Invocations.

The next proof is normalizing a validated snapshot into Assessment Resources,
Relationships, and Evidence.

## Proof 0 — Commercial problem

**Question:** Will an organization pay for a Digital Estate Assessment outcome?

- define the buyer, trigger, scope, evidence request, and deliverable;
- test it against recent Canadian Sitecore/Drupal opportunities;
- obtain a paid pilot or strong design partner commitment;
- manually perform work where software does not yet exist.

**Exit evidence:** a real engagement shape and outputs that affect a customer's
decision.

## Proof 1 — Platform skeleton

**Question:** Can one independent OTP Application run on a small shared platform?

Build only the core, web shell, runtime conventions, and Digital Estate
Assessment Application boundary. Prove its own tables, workers, navigation,
authentication, Application Instances, and Oban execution.

## Proof 2 — Capability runtime

**Question:** Can Contexla execute small versioned operations reliably?

- one Capability contract with a native Elixir Processor (implemented);
- one isolated Python Processor for a real assessment Capability;
- manifests, structured input/output, Bindings, permissions, timeout, result,
  Invocation history, and tests.

Avoid a sophisticated sandbox until this process-level proof works.

## Proof 3 — Assessment vertical slice

**Question:** Can the product create a valuable assessment from real evidence?

- import a controlled Drupal estate snapshot;
- normalize inventory through a Client/Adapter boundary;
- persist an Application Instance and Run;
- generate several deterministic findings with linked evidence;
- render a useful report;
- support repeat execution and comparison.

## Proof 4 — Agent-operated assessment

**Question:** Can an agent turn user intent into a safe, reviewable assessment
configuration?

The agent inspects the registry, explains missing access, proposes configuration,
starts an authorized Run, and summarizes evidence. Manual operation continues to
work unchanged.

## Proof 5 — Agent-created Capability

**Question:** Can an agent add a small operation without changing the platform?

Use a controlled development flow to generate, test, review, register, and bind
one isolated Python Processor. Define a new Capability contract only when the
semantic operation is actually absent. Do not permit unrestricted production
generation.

## Proof 6 — Live Drupal integration

**Question:** Does a repeatable read-only integration materially improve the
assessment?

Choose direct API, customer-run collector, or Drupal Connector based on evidence
from pilots. Add encrypted Connections and incremental acquisition only as
needed.

## Proof 7 — Reuse

**Question:** Is Contexla a platform rather than assessment-specific software?

Build the next commercially validated Application—likely Accessibility Monitor,
Migration Verification, or Content Integrity—and reuse proven execution,
Connections, artifacts, Capabilities, and UI conventions.

## Later direction

Only after the above proofs should the platform expand toward Content Transport,
publishing gates, broader CMS migration, syndication, and deeper autonomous
planning.

