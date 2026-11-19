# Synthetic college Drupal estate

This fixture creates a deliberately small, non-production Drupal estate for
testing Digital Estate Assessment.

It adds:

- Department, Program, and Emergency Alert content types;
- deterministic fields and aggregate sample content;
- content-editor and site-manager roles;
- an editorial moderation workflow;
- two custom modules representing SIS/catalog and search integrations;
- fake `.invalid` integration endpoints and no credentials.

The fixture is idempotent. It is not intended to model every college feature.
Its purpose is to produce known inventory, known evidence gaps, and repeatable
changes for Contexla tests.

The custom modules intentionally omit owner and repository metadata so the
current deterministic assessment rules produce evidence-backed technical-debt
findings.

Never deploy this fixture to a real Drupal installation.

## Local reset note

A DDEV snapshot preserves the database, not the Drupal codebase. Restoring a
pre-fixture database snapshot disables the fixture modules but does not remove
their directories. To reproduce the original code inventory as well, also
remove only these fixture-owned directories from the disposable project:

```text
web/modules/custom/college_catalog
web/modules/custom/college_search
```

Do not use broad cleanup commands against a customer or shared Drupal project.
