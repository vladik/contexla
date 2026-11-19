# Architecture decision records

Use ADRs for consequential decisions that are costly to reverse or that future
contributors may otherwise revisit without context.

## Format

Create `NNNN-short-title.md` containing:

```text
# Title

Status: Proposed | Accepted | Superseded
Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```

## Accepted decisions

- [0001 — One organization per installation](0001-one-organization-per-installation.md)
- [0002 — Applications and Application Instances](0002-applications-and-instances.md)
- [0003 — Digital Estate Assessment is the first Application](0003-digital-estate-assessment-first.md)
- [0004 — Applications own their domains](0004-application-owned-domains.md)
- [0005 — Controlled packages for trusted OTP extensions](0005-controlled-trusted-packages.md)
- [0006 — Manual UI and agents share services](0006-manual-and-agent-service-boundary.md)
- [0007 — Isolated out-of-process Python Processors](0007-isolated-python-processors.md)
- [0008 — Immutable content-addressed Artifact storage](0008-content-addressed-artifacts.md)
- [0009 — Capability contracts and Processor implementations](0009-capability-processor-runtime.md)
- [0010 — Bundled Application domain and infrastructure execution boundary](0010-bundled-application-domain-execution.md)

- [0011 — Independent Application packages](0011-independent-application-packages.md)

Create additional ADRs when implementation makes choices concrete, for
example:

- umbrella application layout and package boundaries;
- Application migration lifecycle;
- encrypted secret storage;
- external Processor protocol and package lifecycle;
- artifact storage contract.

