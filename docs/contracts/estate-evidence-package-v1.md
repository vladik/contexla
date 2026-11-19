# Estate evidence package v1

Status: Draft

The evidence package is the first acquisition contract for Digital Estate
Assessment. It lets a customer or assessor provide approved evidence without
granting Contexla live access to a CMS.

This is an acquisition envelope, not the normalized Assessment domain model.
A source Adapter converts package contents into a Snapshot.

## Package form

The package is a ZIP archive with this logical structure:

```text
estate-evidence.zip
  manifest.json
  sources/
    ... source-native JSON, CSV, text, or configuration exports
  documents/
    ... approved diagrams, inventories, and notes
```

Only `manifest.json` is structurally required. The Assessment scope defines
which evidence files are expected.

## Manifest example

```json
{
  "contract": "contexla.estate-evidence-package",
  "version": "1.0",
  "profile": {
    "id": "contexla.drupal-snapshot",
    "version": "1.0"
  },
  "package_id": "college-drupal-prod-2026-11-19",
  "created_at": "2026-11-19T15:00:00Z",
  "producer": {
    "type": "manual",
    "name": "assessment-team",
    "version": "1"
  },
  "source": {
    "system": "drupal",
    "installation_id": "college-public-web",
    "environments": ["production"]
  },
  "collection": {
    "mode": "customer_export",
    "started_at": "2026-11-19T14:30:00Z",
    "completed_at": "2026-11-19T14:35:00Z",
    "limitations": [
      "Database content values excluded",
      "Infrastructure inventory supplied separately by interview"
    ]
  },
  "classification": "customer-confidential",
  "files": [
    {
      "path": "sources/drupal-system.json",
      "kind": "drupal.system",
      "media_type": "application/json",
      "sha256": "<lowercase hex sha256>",
      "bytes": 12345,
      "collected_at": "2026-11-19T14:34:00Z",
      "contains_secrets": false,
      "classification": "customer-confidential"
    }
  ]
}
```

## Required manifest properties

- `contract` — exactly `contexla.estate-evidence-package`;
- `version` — contract version;
- `profile` — optional source-specific contract layered over this envelope;
- `package_id` — unique within the originating installation or engagement;
- `created_at` — UTC package creation time;
- `producer` — tool or human process that created the package;
- `source.system` — source family such as `drupal`;
- `source.installation_id` — stable customer-approved identifier;
- `collection.mode` — how evidence was acquired;
- `classification` — overall sensitivity classification;
- `files` — declared package files and their hashes.

## File declaration

Every file except `manifest.json` must be declared. A declaration includes:

- normalized relative path;
- semantic `kind` used for Adapter routing;
- media type;
- SHA-256 hash and byte length;
- collection time when known;
- secret-content declaration;
- sensitivity classification.

The package validator must reject:

- absolute paths, parent traversal, or undeclared files;
- duplicate or case-conflicting paths;
- hashes or lengths that do not match;
- unsupported contract versions;
- encrypted archives it cannot inspect;
- files exceeding configured limits;
- any file declared as containing secrets unless an explicit import policy
  permits it.

Rejecting a package does not imply the source estate is invalid; it means the
evidence envelope cannot be trusted or processed safely.

## Initial Drupal evidence kinds

These names are provisional until tested against real exports:

- `drupal.system` — Drupal/PHP/database version and installation metadata;
- `drupal.modules` — module inventory and status;
- `drupal.themes` — theme inventory and status;
- `drupal.configuration` — approved configuration metadata or export;
- `drupal.content_model` — entity types, bundles, fields, and taxonomies;
- `drupal.sites` — multisite/site and hostname metadata;
- `drupal.scheduled_work` — cron, queues, and scheduled tasks;
- `estate.integrations_declared` — interview- or owner-declared integrations;
- `estate.infrastructure_declared` — declared infrastructure services;
- `estate.repositories_declared` — declared source repositories and ownership;
- `assessment.document` — diagrams, inventories, or supporting documents.

The first pilot decides which source kinds deserve a repeatable collector.

## Security rules

- Do not include passwords, API tokens, private keys, session material, database
  rows containing personal data, or environment secret files.
- Hash and validate the package before parsing source files.
- Apply uncompressed-size, file-count, and per-file limits before extraction.
- Extract only to a dedicated temporary directory and never execute package
  contents.
- Preserve the original package hash and validation result.
- Apply configured retention and deletion policy to both archives and extracted
  material.
- Do not send evidence to an AI provider without explicit customer approval and
  a recorded policy decision.

## Evolution

Backward-incompatible changes require a new contract version. Source-specific
evidence kinds can evolve independently when their parser/Adapter version is
recorded on the resulting Snapshot.

