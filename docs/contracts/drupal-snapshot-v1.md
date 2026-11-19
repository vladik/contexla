# Drupal snapshot v1

Status: Draft for the first college assessment

The Drupal snapshot is a source-specific profile of the
[Estate evidence package](estate-evidence-package-v1.md). It is created by a
read-only, customer-run collector or an equivalent reviewed manual procedure.

The collector is a non-persistent Connector. It runs inside or near Drupal,
writes approved metadata, packages it, and exits. It does not provide Contexla
with continuing production access.

## Collection principles

- Collect metadata required by the agreed assessment, not content bodies.
- Use read-only Drupal, Composer, filesystem, and database operations.
- Never collect secrets, private keys, database connection strings, sessions, or
  personal data.
- Record collection limitations and command/tool versions.
- Allow the customer to inspect the unpacked files before delivery.
- Produce deterministic JSON ordering where practical and SHA-256 checksums for
  every file.
- Work without internet access after required collector dependencies are made
  available.

## Candidate package layout

```text
contexla-drupal-snapshot.zip
  manifest.json
  checksums.json
  sources/
    composer.json
    composer.lock
    drupal-status.json
    modules.json
    themes.json
    sites.json
    content-types.json
    fields.json
    views.json
    workflows.json
    roles-summary.json
    content-counts.json
    media-counts.json
    cron.json
    configuration-index.json
  config/
    ... optional sanitized Drupal configuration export
  documents/
    ... optional customer-approved architecture evidence
```

`manifest.json` follows the evidence-package envelope and declares each file's
semantic kind. `checksums.json` is convenient for customer inspection; the
manifest remains authoritative during import.

The manifest must declare this source profile:

```json
{
  "profile": {
    "id": "contexla.drupal-snapshot",
    "version": "1.0"
  }
}
```

## File purposes

| File | Purpose | Initial requirement |
| --- | --- | --- |
| `composer.json` | Declared PHP/Drupal dependencies, repositories, scripts | Required when Composer is used |
| `composer.lock` | Resolved dependency names and versions | Required when Composer is used |
| `drupal-status.json` | Drupal/runtime/database metadata and environment identity | Required |
| `modules.json` | Core, contributed, and custom module inventory and status | Required |
| `themes.json` | Theme inventory, type, parent/base theme, and status | Required |
| `sites.json` | Multisite/site identifiers and approved hostname metadata | Required |
| `content-types.json` | Entity type and bundle definitions | Required for content architecture |
| `fields.json` | Field definitions and attachment to bundles | Required for content architecture |
| `views.json` | View/display definitions and selected dependency metadata | Optional in first import |
| `workflows.json` | Workflow and moderation definitions | Optional in first import |
| `roles-summary.json` | Role identifiers and permission counts/categories, without users | Optional |
| `content-counts.json` | Aggregate counts by entity/bundle/status/language | Optional; no content values |
| `media-counts.json` | Aggregate media/file counts by type/status | Optional |
| `cron.json` | Cron, queue, and scheduled-task metadata | Optional |
| `configuration-index.json` | Index of included configuration names and hashes | Required if `config/` is included |

The engagement specification decides which optional files are required for a
given Run. Missing optional evidence becomes an explicit limitation; parsers do
not fabricate empty inventories.

## Source versus declared evidence

Some outputs can be collected from Drupal deterministically. Others usually
need customer declaration or documents:

- infrastructure topology;
- external-system purpose and criticality;
- integration ownership;
- operational support model;
- undocumented scripts outside the Drupal codebase;
- business disposition and modernization intent.

These belong in separately identified declared evidence rather than being
guessed from configuration.

## Adapter output boundary

The Drupal Assessment Adapter validates the snapshot profile and produces:

- normalized Resources with source-native identifiers;
- typed Relationships;
- Evidence references for every mapped value;
- collection limitations and unmapped records;
- deterministic Adapter diagnostics.

It does not assign modernization disposition, business severity, or final
recommendations. Those belong to Assessment rules and architect review.

The initial implementation maps Drupal status, modules, themes, sites, content
types, fields, Views, workflows, role summaries, aggregate content/media counts,
and scheduled jobs when those JSON documents are present. It preserves missing
evidence as a limitation rather than producing empty inventory. Composer
manifests are passed to the separately versioned Composer Capability rather than
interpreted inside the Adapter.

## Open questions for the collector spike

The first local proof uses a read-only Drush `php:script` collector. This is an
implementation spike, not yet the production Connector contract. It exists to
test the package shape against a disposable Drupal 11 installation before the
college evidence determines whether a Drupal module or another delivery form is
needed.

- Which data is available consistently through Drush across supported Drupal
  versions?
- Should the collector be a shell/Drush script, a small PHP package, or a Drupal
  module invoked only for collection?
- How should multisite identity and shared codebases be represented?
- Which configuration values require redaction beyond known secret keys?
- How are custom modules and themes distinguished reliably across Composer and
  filesystem layouts?
- Can actual component/template usage be measured without collecting content
  values?
- What maximum archive size is acceptable for customer review and upload?

Answer these against the college environment before locking version 1.0.

