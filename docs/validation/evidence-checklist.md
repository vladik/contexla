# Evidence request checklist

This is a scope menu, not a demand for unrestricted access. Request only the
evidence needed for the agreed decision and prefer read-only exports or customer-
run collection.

## Estate boundaries

- CMS product, edition, version, and installation identifiers;
- environments and their purpose;
- sites, hostnames, languages, regions, and business owners;
- hosting and support vendors;
- known modernization or retirement plans.

## CMS configuration

- installed modules, packages, plugins, and versions;
- enabled/disabled status where available;
- configuration export with secrets removed;
- content types, fields, taxonomies, workflows, roles, and permissions;
- scheduled jobs, queues, publishing targets, and caches;
- component, template, layout, or presentation definitions.

## Usage and scale

- counts by content type, language, status, and site;
- content and asset growth where available;
- component/template usage;
- active versus unused modules and features;
- traffic or access indicators needed to prioritize sites;
- broken, orphaned, stale, or duplicate indicators if already known.

## Integrations

- architecture and data-flow diagrams;
- APIs consumed and exposed;
- webhooks, message queues, file transfers, and scheduled imports/exports;
- search, DAM, analytics, CRM, ERP, identity, translation, forms, email, and
  personalization systems;
- system owner, authentication method, direction, frequency, and criticality;
- contracts or interface documentation where permitted.

## Custom implementation

- source repositories or bounded code exports;
- custom modules/packages and ownership;
- build and deployment definitions;
- environment-specific configuration with secrets removed;
- known workarounds, unsupported code, and abandoned functionality;
- dependency and package lock files.

## Infrastructure and operations

- deployment topology and runtime versions;
- databases, storage, CDN, search, queues, and scheduled infrastructure;
- backup, restore, disaster recovery, and monitoring overview;
- deployment frequency and release ownership;
- support model, operational incidents, and known capacity constraints;
- license and renewal dates where relevant to the decision.

## Governance and quality

- accessibility policy and recent audit results;
- security classifications and data-retention requirements;
- content ownership and approval workflows;
- localization process;
- regulatory or evidence-retention obligations;
- existing content-quality reports.

## Collection safety

Before collection, agree on:

- permitted systems, environments, endpoints, and time windows;
- data classifications that must not leave the customer environment;
- credential method and least-privilege role;
- redaction requirements;
- encryption in transit and at rest;
- retention and deletion dates;
- who may access raw evidence and final reports;
- whether AI providers may receive any information (default: no unless explicitly
  approved).

Never request production passwords in email or embed secrets in an evidence
archive. Missing evidence should become a recorded assessment limitation, not a
reason to weaken access controls.

