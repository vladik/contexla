# 0019: Typed Application runtime services

- Status: Accepted
- Date: 2026-11-21

## Context

Independent Applications require bounded access to shared platform facilities,
including Instances, Artifacts, Adapters, Capabilities, Operations, jobs, and
the Ecto Repo used for Application-owned tables. The first proof dispatched
calls by service and function atom through `Runtime.call/3`. That preserved
compile-time independence but allowed an Application to name any exported
platform function and hid the real public contract from tooling and authors.

## Decision

`Contexla.Applications.Sdk.Runtime` exposes explicit named functions for every
supported host service. The SDK also owns the `PlatformServices` behaviour; the
platform supplies an implementation at runtime and verifies it at compile time.

Concrete Applications compile only against the SDK functions. They do not call
`Contexla.ApplicationServices`, dynamically dispatch platform function names,
or depend on other platform modules. A new shared service requires an explicit
SDK contract change and platform implementation.

The SDK exposes the configured Ecto Repo module because trusted OTP
Applications own Ecto schemas and transactions while sharing the installation's
database and pool. This does not transfer ownership of Application tables to the
platform.

## Consequences

- the supported Application-to-platform boundary is discoverable and testable;
- refactoring internal platform modules does not change Application code;
- Application packages remain independently compilable;
- service authorization and actor scoping remain platform responsibilities;
- adding a runtime service is intentionally a reviewed public-contract change;
- untrusted Processors do not receive this trusted in-process SDK boundary.
