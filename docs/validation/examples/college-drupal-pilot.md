# College Drupal pilot hypothesis

Status: Working hypothesis requiring customer discovery

This document translates the known opportunity—an organization such as a
college needs an audit of its Drupal-based infrastructure, inventory, and
integrations—into a candidate pilot. It is not a statement of the customer's
confirmed requirements.

## Hypothesized decision

The college needs a defensible understanding of its current Drupal estate before
planning continued operation, an upgrade, vendor transition, consolidation, or
modernization investment.

Confirm which decision is actually pending. An inventory without a decision
deadline is less likely to receive budget or executive attention.

## Candidate scope

- one Drupal installation or a clearly named set of related installations;
- production and one non-production environment where comparison is useful;
- public sites hosted by that installation;
- Drupal core, PHP/runtime, modules, themes, configuration metadata, content
  model, scheduled work, custom code, declared integrations, and infrastructure;
- architecture documents and interviews with the application owner, hosting or
  operations lead, and a representative content owner.

Possible exclusions for the pilot:

- content-body export;
- personal information;
- penetration testing;
- formal accessibility certification;
- full code review;
- migration mapping or target selection;
- systems not connected to the scoped Drupal installation.

## Questions to resolve in the first customer session

1. What decision will the audit support, and by what date?
2. Is the estate one installation, Drupal multisite, or several independently
   operated codebases?
3. Which Drupal and PHP versions and hosting models are believed to exist?
4. Who owns the application, hosting, code, content, and integrations?
5. Is there a current vendor, and is source/configuration documentation
   available?
6. Can the customer run read-only Drush/Composer/configuration commands or a
   reviewed collector?
7. Can they provide a sanitized snapshot outside their environment, or must all
   analysis run on-premise?
8. Which integration failures or unknowns cause the greatest concern?
9. Does the audit need to determine actual usage, merely configuration, or both?
10. What report or inventory will change the pending decision?

## Proposed evidence path

Prefer, in order:

1. customer-generated sanitized evidence package;
2. assessor-guided export using standard Drupal/Composer/Drush facilities;
3. approved read-only connection;
4. a small Drupal Connector only if the first three cannot provide repeatable
   required evidence.

This ordering tests the Contexla ingestion and Adapter model without making
installation of a custom Drupal module a condition of the pilot.

## Candidate deterministic outputs

- installation/environment/site inventory;
- Drupal, runtime, module, and theme inventory;
- contributed versus custom extension classification;
- content-type and field summary;
- declared integration register with ownership/evidence gaps;
- infrastructure and repository register;
- conflicting or missing identifiers and versions;
- missing ownership or maintenance metadata;
- differences between comparable environment snapshots;
- assessment limitations caused by unavailable evidence.

Any lifecycle, security, or support-status claim must use a current cited data
source and an explicit rule version.

## Candidate expert outputs

- areas requiring deeper code or integration analysis;
- likely retain, retire, replace, consolidate, upgrade, migrate, or investigate
  disposition;
- modernization sequencing considerations;
- risks that could change cost or schedule;
- recommended next technical proofs.

These must be labeled as architect conclusions and linked to supporting evidence
and rationale.

## Pilot success test

The pilot succeeds if the customer can use the assessment to make or de-risk a
specific modernization decision, and if at least one repeated evidence-to-
finding path is clear enough to productize.

Likely first automation candidate:

```text
sanitized Drupal evidence package
  -> validation
  -> Drupal normalization
  -> inventory
  -> evidence-gap and ownership findings
  -> report projection
```

The technical discovery session should confirm or replace this candidate before
implementation begins.

