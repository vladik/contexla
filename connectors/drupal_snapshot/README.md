# Drupal snapshot collector spike

This directory contains the first read-only collector spike for the Drupal
Digital Estate Assessment path.

It is deliberately a Drush PHP script rather than an installed Drupal module.
The spike exists to validate which Drupal metadata is useful and consistently
available before Contexla commits to a long-lived Connector package.

## Safety boundary

The collector:

- reads Drupal extension, site, content-model, and aggregate-count metadata;
- copies Composer manifests when they are present;
- does not read content field values;
- does not export configuration values, credentials, users, sessions, or
  environment files;
- writes a new ZIP under `.contexla-snapshots/` in the Drupal project root;
- does not change Drupal configuration or database state.

The resulting package follows
[`docs/contracts/drupal-snapshot-v1.md`](../../docs/contracts/drupal-snapshot-v1.md).

## Run inside a Drupal project

Copy `collector.php` into a location visible to the Drupal/Drush runtime, then
run:

```bash
CONTEXLA_INSTALLATION_ID=local-drupal-11 \
CONTEXLA_ENVIRONMENT=local \
drush php:script /absolute/path/to/collector.php
```

For DDEV, execute the same command through `ddev exec`. The script prints the
absolute path of the generated ZIP.

This is a development proof. Review the unpacked package before using it with
customer evidence.
