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

## Real production scenario

A university publishes roughly one hundred academic programs. Each program's
facts (name, credential, duration, delivery mode) must stay consistent across:

```text
ERP (authoritative data)          ← scope master: Sitecore
        → delivery API (JSON)
        → public website (HTML)
        → search index (HTML)
        → PDF catalog (future)
```

The key characteristics that drive the domain design:

- **Scope is not in the data master.** Sitecore (not ERP) defines which
  programs exist — their codes and active status. ERP defines the authoritative
  values for each program once its code is known. These are separate concerns:
  one source is the **scope master**, another is the **data master**.

- **Sources have different fetch strategies.** ERP may require one HTTP call per
  program. The delivery API may return all programs in a single response. Each
  source declares its `fetch_strategy` (`per_item` or `bulk`) so the executor
  knows how to acquire data at run time without coupling source definitions to
  executor logic.

- **Propagation takes time.** If the CMS syncs from ERP three times a day,
  running a monitor immediately after an ERP update will produce false positives.
  Each source declares an `allowed_delay_seconds` window; a disagreement within
  that window is `pending` (not an issue), beyond it is `overdue` or `mismatch`.

- **Sync windows are known.** Known sync schedules (3×/day CMS sync, nightly ERP
  export) can be encoded as maintenance windows. The monitor skips a scheduled
  run during a window rather than producing noise that must later be suppressed.

## Collection model

A Monitor tracks a **collection** — a named, dynamically resolved set of
entities — not a single entity.

### Scope source

One source is designated as the **scope master**. At the start of each run, the
executor queries the scope master to discover the current list of entity IDs. The
monitor compares only the entities that exist in that list; entities removed from
scope are no longer checked.

The scope master is itself a source with a declared role. It may also carry
facts (e.g., Sitecore providing both program codes and program names), or it may
carry only identity information and no compared facts.

### Data master

One source is designated as the **data master** (role: `authority`). It provides
the reference values for each fact. Representation sources are compared against
the data master's values.

A monitor has exactly one scope master and exactly one data master. They may be
the same source (scope master can also be the authority) or different sources.

### Fetch strategy

Each source declares how the executor should acquire data for the full
collection:

- `bulk` — one request returns data for all entities (e.g., a paginated API
  returning all programs). The executor makes one or a small number of calls and
  extracts entity-keyed values.
- `per_item` — one request per entity ID (e.g., ERP requiring `GET /programs/:id`
  for each program). The executor fans out using IDs from the scope source.

Fetch strategy is stored on the source, not in the executor. The executor reads
the declared strategy and dispatches accordingly.

### Propagation window

Each source declares `allowed_delay_seconds`. A disagreement observed within
that window produces state `pending` (no issue). A disagreement that exceeds the
window produces `overdue` or `mismatch` (issue created). The propagation window
is per-source because different delivery paths have different expected latencies.

## Scheduling and maintenance windows

### Scheduled runs

Each Monitor can declare an Oban cron expression (e.g., `"0 */4 * * *"` for
every four hours). Oban manages the schedule; the monitor's cron expression is
registered as an Oban cron job keyed to the monitor ID when the monitor is
created or updated.

### Maintenance windows

Maintenance windows represent known periods when comparison results are
unreliable — a CMS sync window, a nightly ERP export, a planned downtime.

Windows are stored as iCal RRULE strings using the `cocktail` hex package. This
standard recurrence format supports:

- time-of-day windows (e.g., 02:00–04:00 UTC daily);
- day-of-week restrictions (weekdays only, weekends only);
- multiple windows per monitor (e.g., three CMS sync windows per day).

When a scheduled Oban job fires for a monitor, the executor checks whether the
current time falls within any active maintenance window **before** starting a
run. If yes, the job returns `:ok` immediately — no run is created, no snooze is
queued. The absence of a run during a window is the correct and expected
outcome; the gap in run history documents it.

Maintenance windows are a scheduling concern only. Manual runs (triggered from
the UI or via webhook) always proceed regardless of windows.

### Relationship between scheduling and propagation

These are distinct controls:

| Control | Purpose | Location |
|---|---|---|
| `cron_expression` | When to start a run | Monitor |
| Maintenance window (RRULE) | Skip run during known unreliable periods | Monitor |
| `allowed_delay_seconds` | How long a disagreement is `pending` before becoming `overdue` | Source |

A maintenance window prevents a run from starting. The propagation window
governs what state an observation gets once a run does execute.

## Run triggers

A run can be started three ways:

- **Scheduled** — Oban cron fires the job on the monitor's declared schedule.
  The job checks maintenance windows and either starts a run or returns `:ok`.
- **Manual full** — UI or API triggers `integrity.run` for the full collection.
  Maintenance windows are ignored.
- **Manual specific** — Webhook or UI triggers `integrity.run_item` for a
  single entity ID. Useful for incident investigation or spot-checking a
  recently updated record.

## Domain ownership

The Application owns these concepts and tables in the `contexla_integrity`
PostgreSQL schema:

```text
integrity_monitors
integrity_sources
integrity_fact_definitions
integrity_schedule_windows
integrity_runs
integrity_source_checks
integrity_observations
integrity_issues
integrity_evidence
```

### Monitor

A recurring integrity question for a named collection of entities. It owns the
collection key, scope source designation, cron expression, and links to its
Sources and Fact Definitions.

New fields beyond the initial slice:

- `collection_key` — a human-readable identifier for the collection (e.g.,
  `programs`);
- `scope_source_id` — foreign key to the Source used for entity discovery;
- `cron_expression` — Oban cron string; `nil` means no scheduled runs.

### Source

A configured evidence location. V1 supports `json` and `html` source formats
over HTTP. A Source declares its role (`scope_master`, `authority`, or
`representation`), URL or URL template, extraction mapping, fetch strategy,
and allowed delivery delay.

New fields beyond the initial slice:

- `fetch_strategy` — `bulk` or `per_item`;
- `item_url_template` — URL template with an `:id` placeholder for per-item
  sources (e.g., `https://erp.example.com/api/programs/:id`);
- `scope_key_path` — JSON path or CSS selector used to extract entity IDs
  when this source is the scope master.

### Fact Definition

The Application-level meaning and deterministic comparison policy for one
fact. V1 comparison is normalized exact equality. Normalization is limited to
trimmed whitespace and case-sensitive string values.

### Schedule Window

A maintenance window stored as an iCal RRULE string plus a duration in seconds.
A monitor may have zero or more Schedule Windows. The executor evaluates all
windows at scheduled run time; any matching window suppresses the run.

### Run

One durable execution of a Monitor. It records status, timing, collection size
(number of entities checked), summary counts, and the Tool Invocations used to
produce observations.

### Observation

One value observed for a fact at a Source for one entity during a Run, with
observed/source timestamps and evidence identity.

### Issue

An Application-owned operational problem. V1 issue kinds are `mismatch`,
`missing`, `overdue`, and `unavailable`. Issues have open, acknowledged, and
resolved lifecycle states. A healthy or still-within-delay observation does
not create an Issue.

### Evidence

The bounded source response and extraction provenance supporting an
Observation or Issue. Evidence must not contain stored credentials.

## Integrity states

Each fact/source/entity observation has one deterministic state:

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

The Application performs scope discovery, acquisition (bulk or per-item),
normalization, timing evaluation, comparison, Issue lifecycle, persistence, and
presentation. Tool Invocations are created before execution and linked to the
parent Application Run.

## Operations

```text
integrity.run              start a full Run for a Monitor (manual, collection-wide)
integrity.run_item         start a Run for a single entity ID
integrity.issue.acknowledge
integrity.issue.resolve
integrity.demo_setup       create the synthetic monitor (dev only)
```

Scheduled runs are triggered by Oban cron, not by an Operation call. The Oban
job calls the same run logic as `integrity.run`; the job result is linked to
the Run record.

Read surfaces query Application services directly through authenticated,
Instance-scoped LiveViews. Future Agent operation uses the same Operations and
services; the Agent does not write Application tables directly.

## UI surfaces

The Application follows the shared Application frame and exposes:

- **Overview** — aggregate health across all configured monitors; fact × source
  health summary at collection level (counts and percentages, not per-item rows);
  open Issue count; last Run; Run action;
- **Monitors** — configured integrity questions, their Sources, fact definitions,
  schedule, and maintenance windows; create/edit/delete monitor management (not
  yet built);
- **Issues** — active and historical mismatches with evidence;
- **Runs** — Run history and per-run collection summary;
- **Evidence** — retained bounded observations and provenance;
- **Settings** — Application-owned configuration;
- **Developer** (dev only) — simulator control, quick-start, and source
  endpoints.

The initial implementation combined Monitors, Runs, and Issues on Overview as a
per-entity fact × source matrix for the synthetic single-entity scenario. The
collection-based production UI will show aggregate counts at the monitor level;
per-entity detail is available on drill-down.

## Explicit v1 exclusions

- automatic remediation or synchronization;
- writes to external content systems;
- vendor-specific Sitecore, ERP, search, DAM, or CMS packages;
- multiple Azure CD-node inspection;
- PDF generation, PDF extraction, or OCR;
- accessibility validation or certification;
- semantic or AI-based fact comparison;
- autonomous Agent setup;
- notifications and alerting;
- generic workflow or visual composition builder.

## Acceptance criteria

### Completed (synthetic single-entity slice, 2026-11-24)

1. install and create a Content Integrity Monitor Instance;
2. create the synthetic program Monitor (via `integrity.demo_setup`);
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

### Next slice — collection-based production model

1. Create a monitor that declares a scope source, a data master, and one or more
   representation sources, each with a declared fetch strategy;
2. Run the monitor against a collection of N entities; scope discovery populates
   the entity list at run time;
3. Bulk sources are fetched once and keyed by entity ID; per-item sources fan out
   per entity;
4. The propagation window (`allowed_delay_seconds`) correctly produces `pending`
   vs `overdue` vs `mismatch` states;
5. A cron expression on a monitor registers with Oban and fires scheduled runs;
6. A maintenance window (RRULE via `cocktail`) suppresses a scheduled run when
   the current time falls within it; the job returns `:ok` and no Run record is
   created;
7. Manual runs always proceed regardless of maintenance windows;
8. The Overview shows aggregate health counts per monitor (not a per-entity
   matrix) for collections of meaningful size;
9. The Monitors surface supports creating and editing a monitor with sources,
   facts, schedule, and maintenance windows.

## Validation and stop condition

After the synthetic demonstration works, use it in direct outreach and buyer
conversations. Continue investment when prospects recognize the problem and
request a pilot, source integration, managed monitoring, or related delivery
work. Reconsider the product if targeted prospects consistently cannot name
important cross-system facts or do not value evidence-backed detection enough
to fund integration or operation.
