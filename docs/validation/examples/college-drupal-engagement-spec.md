# College Drupal Digital Estate Assessment

Status: Draft engagement specification

This is the paid-assessment specification that should be completed with the
college. Bracketed items and questions are unresolved; they are not product
requirements until confirmed.

## Engagement purpose

Create an evidence-backed inventory of the college's Drupal estate and identify
dependencies, risks, technical debt, unknowns, and modernization considerations
that affect **[decision to confirm]** by **[decision date to confirm]**.

Candidate decisions include continuing the current operating model, upgrading
Drupal, changing implementation/support vendors, consolidating sites, or
planning a future replatform.

## Sponsor and users

```text
Executive sponsor: [confirm]
Decision owner: [confirm]
Application owner: [confirm]
Infrastructure/hosting owner: [confirm]
Content owner representative: [confirm]
Security/privacy contact: [confirm]
Primary report audience: [confirm]
```

## Scope boundary

```text
Drupal installation(s): [confirm]
Codebase(s): [confirm]
Sites/domains: [confirm]
Environments: [confirm]
Hosting/platform: [confirm]
Assessment period: [confirm]
Explicit exclusions: [confirm]
```

The pilot should initially be bounded to one installation or related codebase
unless the college's decision explicitly requires cross-estate comparison.

## Questions the assessment must answer

1. What Drupal installations, sites, environments, domains, and runtime versions
   are in the agreed scope?
2. Which core, contributed, and custom modules and themes are installed and
   enabled?
3. Which content types, fields, media types, Views, workflows, and roles define
   the current content architecture?
4. Which definitions appear to be used, unused, duplicated, or impossible to
   evaluate with available evidence?
5. Which external systems does Drupal integrate with, in which direction, using
   what authentication class, and under whose ownership?
6. Which infrastructure services and repositories are required to build,
   deploy, operate, search, cache, and serve the estate?
7. Which custom code and dependencies create maintenance or modernization risk?
8. Which versions or dependencies are unsupported or approaching a relevant
   lifecycle deadline according to current cited sources?
9. What accessibility baseline can be established for agreed public URLs, and
   what is outside that baseline's limits?
10. Which material unknowns require interviews or deeper technical analysis?
11. What should be retained, retired, replaced, consolidated, upgraded,
    migrated, or investigated next?

The college must rank these questions. The first paid pilot does not need equal
depth in every area.

## Inputs requested

### Proposed minimum technical snapshot

- `composer.json` and `composer.lock`;
- Drupal/runtime/environment status metadata;
- module and theme inventory;
- site/domain inventory;
- content-type and field definitions;
- sanitized configuration index or approved configuration export;
- known collection limitations.

### Requested when available and approved

- Drupal code repository or bounded custom-code export;
- Views and workflow definitions;
- content and media aggregate counts;
- role/permission summary without user data;
- cron, queues, and scheduled tasks;
- hosting and infrastructure information;
- architecture and deployment documentation;
- integration configuration with credentials redacted;
- known public URLs for a bounded accessibility baseline;
- read-only API or database access only when the snapshot cannot supply required
  evidence.

### Interviews

- Drupal/application owner;
- infrastructure or hosting owner;
- developer/vendor representative;
- content operations representative;
- integration owners for critical external systems.

## Collection method

The preferred first method is a customer-run, read-only collector producing a
[`contexla-drupal-snapshot.zip`](../../contracts/drupal-snapshot-v1.md). The
college can inspect and approve the unpacked contents before transferring it.

Persistent production credentials are not required. If the college requires
all evidence to remain on-premise, Contexla analysis will run in the approved
environment and only approved reports/exports will leave it.

## Deliverables

1. **Executive summary** tied to the confirmed decision.
2. **System and site inventory** covering scoped installations, environments,
   domains, versions, owners, and evidence gaps.
3. **Module, theme, and custom-code inventory** with status, origin, version,
   usage evidence where available, and lifecycle observations based on cited
   sources.
4. **Content architecture** covering content/media types, fields, Views,
   workflows, and selected actual-usage indicators.
5. **Integration map** with direction, purpose, ownership, authentication class,
   criticality, and evidence confidence.
6. **Infrastructure dependency view** covering hosting, databases, search,
   storage, CDN/cache, queues, repositories, build/deploy, and scheduled work as
   evidence permits.
7. **Accessibility baseline** for **[URLs and standard to confirm]**, explicitly
   distinguished from certification.
8. **Findings register** covering operational risk, technical debt, unsupported
   dependencies, missing ownership, conflicts, and unknowns.
9. **Modernization recommendations** with retain/retire/replace/consolidate/
   upgrade/migrate/investigate dispositions where evidence supports them.
10. **Evidence appendix and machine-readable export** with provenance,
    collection dates, hashes where appropriate, and stated limitations.

## Finding contract

Each material Finding includes:

- category;
- impact/severity;
- confidence;
- concise summary and explanation;
- affected Resources;
- recommendation;
- Evidence references;
- deterministic rule/version or named expert origin;
- review status and rationale.

## Exclusions unless added to scope

- migration implementation or complete source-to-target mapping;
- target-platform procurement;
- penetration testing or vulnerability certification;
- formal accessibility certification;
- collection of content bodies or personal information;
- performance/load testing;
- remediation of discovered issues;
- guaranteed discovery of integrations absent from technical or interview
  evidence.

## Acceptance criteria

The college accepts the assessment when:

- agreed scope and evidence limitations are accurately represented;
- every material conclusion is linked to Evidence or labeled expert judgment;
- factual corrections from the review are resolved or documented;
- inventories are available in human-readable and machine-readable form;
- recommendations address the confirmed decision rather than generic best
  practices;
- the final workshop explains priority, confidence, unknowns, and next actions.

## Commercial and delivery details to confirm

```text
Fixed scope and fee: [confirm]
Start/date constraints: [confirm]
Customer responsibilities: [confirm]
Evidence delivery deadline: [confirm]
Draft review period: [confirm]
Final workshop date: [confirm]
Data retention/deletion date: [confirm]
On-premise requirement: [confirm]
AI use permitted: no, unless explicitly approved
```

