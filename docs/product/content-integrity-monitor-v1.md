# Content Integrity Monitor v1

## Product hypothesis

Content Integrity Monitor detects when important facts are missing, delayed,
unavailable, or inconsistent across an authoritative source and the digital
representations derived from it.

It is a standalone Contexla Application. It is not a synchronization engine,
remediation product, legal certification, or vendor-specific Sitecore feature.
Its value is operational visibility backed by retained evidence:

> Which important content facts disagree, where, since when, and what evidence
> supports the issue?

The first likely buyers and operators are digital platform, web operations,
content operations, and CMS support teams responsible for content that travels
through several systems before it reaches users.

## First demonstrable scenario

The v1 demonstration monitors program facts through a synthetic but realistic
delivery chain:

```text
authoritative Program API JSON
        -> delivery API JSON
        -> public program page HTML
        -> program-search result HTML
```

The first facts are:

- program name;
- credential;
- duration.

The scenario is intentionally vendor-neutral. ERP, Sitecore, Solr, Coveo,
Drupal, multiple CD nodes, and generated PDF are future source/representation
Adapters or configured endpoints, not assumptions in the Application domain.

## User workflow

```text
Create Application Instance
        -> create Monitor
        -> define authoritative source
        -> define representations
        -> map three facts
        -> test each source
        -> run Monitor
        -> inspect status and evidence-backed Issues
        -> acknowledge or resolve Issues
        -> run again and inspect history
```

The first slice may seed the synthetic Monitor through an explicit demo setup
Operation to shorten demonstration setup. The same domain services must support
normal manual configuration later; the demo must not bypass the Run, Tool, or
evidence boundaries.

## Domain ownership

The Application owns these concepts and tables in the `contexla_integrity`
PostgreSQL schema:

```text
integrity_monitors
integrity_sources
integrity_fact_definitions
integrity_runs
integrity_source_checks
integrity_observations
integrity_issues
integrity_evidence
```

### Monitor

A recurring integrity question for one set of entities and facts. It owns the
timing policy and identifies one authoritative Source plus one or more
representation Sources.

### Source

A configured evidence location. V1 supports `json` and `html` source formats
over HTTP. A Source declares its role (`authority` or `representation`), URL,
extraction mapping, and allowed delivery delay.

### Fact Definition

The Application-level meaning and deterministic comparison policy for one
fact. V1 comparison is normalized exact equality. Normalization is limited to
trimmed whitespace and case-sensitive string values.

### Run

One durable execution of a Monitor. It records status, timing, summary, and
the Tool Invocations used to produce observations.

### Observation

One value observed for a fact at a Source during a Run, with observed/source
timestamps and evidence identity.

### Issue

An Application-owned operational problem. V1 issue kinds are `mismatch`,
`missing`, `overdue`, and `unavailable`. Issues have open, acknowledged, and
resolved lifecycle states. A healthy or still-within-delay observation does
not create an Issue.

### Evidence

The bounded source response and extraction provenance supporting an
Observation or Issue. Evidence must not contain stored credentials.

## Integrity states

Each fact/source comparison has one deterministic state:

```text
healthy      values agree
pending      representation differs but remains inside allowed delivery delay
overdue      representation differs after allowed delivery delay
mismatch     values differ and no delivery delay applies
missing      required fact is absent
unavailable  source acquisition failed
unknown      comparison cannot be completed safely
```

`pending` prevents normal propagation delay from producing false alarms. A Run
uses the authority's declared source timestamp when available; otherwise the
Run observation time is used and the limitation is retained in evidence.

## Tool boundary

The Application pins and requests exact Tool versions:

```text
com.contexla.extract.json-values@1.0.0
com.contexla.extract.html-values@1.0.0
```

Each Tool accepts a fetched document plus a field mapping and returns extracted
values. Tools do not know about programs, authorities, Issues, delay policy, or
Application tables.

The Application performs acquisition, normalization, timing evaluation,
comparison, Issue lifecycle, persistence, and presentation. Tool Invocations
are created before execution and linked to the parent Application Run.

## Initial Operations

```text
integrity.demo_setup   create the deterministic synthetic Monitor
integrity.run          start one durable Monitor Run
integrity.issue.acknowledge
integrity.issue.resolve
```

Read surfaces query Application services directly through authenticated,
Instance-scoped LiveViews. Future Agent operation uses the same Operations and
services; the Agent does not write Application tables directly.

## Initial UI

The Application follows the shared Application frame and exposes:

- **Overview** — current state, open Issue count, last Run, and start action;
- **Monitors** — configured integrity questions and their Sources;
- **Issues** — active and historical mismatches with evidence;
- **Runs** — Run history and execution status;
- **Evidence** — retained bounded observations and provenance;
- **Settings** — Application-owned defaults.

The first implementation may combine Monitors, Runs, and Issues on Overview
until there is enough data to justify separate surfaces. This is a delivery
sequence choice, not a change to the domain.

## Explicit v1 exclusions

- automatic remediation or synchronization;
- writes to external content systems;
- vendor-specific Sitecore, ERP, search, DAM, or CMS packages;
- multiple Azure CD-node inspection;
- PDF generation, PDF extraction, or OCR;
- accessibility validation or certification;
- semantic or AI-based fact comparison;
- autonomous Agent setup;
- notifications and production scheduling;
- generic workflow or visual composition builder.

## Acceptance criteria

The first vertical slice is complete when a user can:

1. install and create a Content Integrity Monitor Instance;
2. create the synthetic program Monitor;
3. start a durable Run through an Application Operation;
4. acquire four synthetic HTTP representations;
5. execute exact JSON/HTML Tool versions through durable Tool Invocations;
6. retain observations and evidence;
7. distinguish healthy, pending, overdue/mismatch, missing, and unavailable
   results deterministically;
8. inspect an evidence-backed Issue in the shared Application UI;
9. run the Monitor again and retain history;
10. demonstrate the outcome in a few minutes without explaining internal
    architecture.

**Technical status (2026-11-24):** all ten criteria are implemented and were
validated against the development-only synthetic source. The repeatable proof
produced an overdue website value and missing search value, then a pending
delivery window, then an unavailable search source, with durable Runs, exact
Tool Invocations, evidence identities, Issue reconciliation, and history. This
is technical acceptance of the bounded slice, not market validation.

## Validation and stop condition

After the synthetic demonstration works, use it in direct outreach and buyer
conversations. Continue investment when prospects recognize the problem and
request a pilot, source integration, managed monitoring, or related delivery
work. Reconsider the product if targeted prospects consistently cannot name
important cross-system facts or do not value evidence-backed detection enough
to fund integration or operation.
