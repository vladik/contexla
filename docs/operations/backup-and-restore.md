# Backup and restore

PostgreSQL and Artifact storage form one recoverable installation. Backing up
only one side is insufficient: database rows identify immutable files under
`CONTEXLA_ARTIFACTS_PATH`.

## Backup

For the first deployment model, take a simple coordinated backup during a
maintenance window:

1. Stop traffic and allow running Oban jobs to finish or stop the serving
   process cleanly.
2. Record the Contexla release version and exact Application, Integration,
   Tool package versions. Do not copy secret values into
   the manifest.
3. Create a PostgreSQL custom-format dump:

   ```powershell
   pg_dump --format=custom --file=contexla.dump $env:DATABASE_URL
   ```

4. Archive the complete Artifact storage directory without changing its
   content-addressed paths:

   ```powershell
   tar -czf contexla-artifacts.tar.gz -C $env:CONTEXLA_ARTIFACTS_PATH .
   ```

5. Hash, encrypt, and move both files plus the non-secret version manifest to
   approved backup storage.
6. Restart the service and verify readiness.

Automated online backups may be added after the deployment environment is
known. They must define a consistency point between PostgreSQL and Artifact
storage and must be restore-tested; filesystem copying alone is not sufficient.

## Restore

Restore into an empty, isolated installation first:

1. Provision a compatible PostgreSQL server and an empty database.
2. Provision an empty Artifact storage directory with ownership restricted to
   the Contexla service account.
3. Restore PostgreSQL with `pg_restore` using the new target connection.
4. Extract the Artifact archive into the configured storage root.
5. Install the recorded Contexla release and exact trusted package versions.
6. Configure new process-level secrets. Restore a required encryption key from
   the approved secret backup when encrypted Connection data exists; it must not
   be regenerated for an existing database.
7. Run `Contexla.Release.migrate_all()` only when intentionally upgrading the
   restored installation.
8. Run `Contexla.Release.diagnostics()`, start the service without public
   traffic, and verify authentication, Artifacts, Instances, and recent Runs.
9. Record restore duration and evidence before promoting the installation.

Never test restore by overwriting the only production database or Artifact
directory.
