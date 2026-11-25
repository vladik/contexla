# Support bundles

An installation administrator can download a support bundle from
`/operations`. The platform builds the ZIP in memory, records
`support_bundle.generated` after successful creation in the append-only audit stream, and returns bundle
identity and SHA-256 headers with the download.

## Contents

Every entry is generated from an explicit allow-list:

```text
manifest.json   bundle identity, schema version, file sizes and checksums
health.json     bounded diagnostics and aggregate execution counts
runtime.json    platform/runtime versions, migration versions, package identities
activity.json   recent safe Operation, Tool Invocation, job, and audit references
```

Activity is bounded to the same recent records shown by the Operations Console.
Application and Integration identity, version, OTP running state, and database
schema identity may be included. Tool identity, version, runtime, and worker
profile may be included. Migration data contains schema owners, status, and applied version
numbers only.

## Exclusions

The generator does not read or serialize:

- credentials or Connection secrets;
- invocation inputs or outputs;
- Oban arguments, metadata, tags, or exception/error bodies;
- audit-event metadata;
- uploaded Artifacts or evidence contents;
- Application-owned domain tables, Runs, findings, or reports;
- raw application or infrastructure logs;
- exception messages or stack traces;
- user email addresses.

Safe persisted error codes and opaque identifiers are included so the recipient
can correlate a bundle with separately controlled installation logs. The bundle
does not export Audit Event subject identifiers because their semantics are
caller-defined. The bundle is diagnostic information and may still reveal
package names, internal worker module names, timestamps, and allow-listed opaque
execution identifiers. Treat it as customer support data and transmit it
through an approved channel.

The bundle is not a backup and cannot restore an installation. See
[Backup and restore](backup-and-restore.md) for the coordinated PostgreSQL and
Artifact-storage procedure.
