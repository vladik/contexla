# Installation and upgrades

## Release contents

The platform is an operating-system-specific BEAM release. Build it on the same
OS/architecture family used by the target host:

```powershell
.\scripts\build-release.ps1
```

The release is written to `platform/_build/prod/rel/contexla`. It intentionally
contains no concrete Application or Integration dependency. A customer
distribution places approved package contents in a separate, versioned package
directory and supplies their `ebin` registrations at runtime.

## Required runtime configuration

Supply secrets through the process environment or an external secret manager,
not a checked-in file:

```text
DATABASE_URL                   PostgreSQL URL
SECRET_KEY_BASE                unique Phoenix signing secret
CONTEXLA_ARTIFACTS_PATH        durable absolute storage path
PHX_HOST                       public host name
PORT                           HTTP port, default 4100
POOL_SIZE                      database pool size, default 10
PHX_SERVER                     set to true only for the serving process
CONTEXLA_APPLICATION_PACKAGES  optional semicolon-separated ebin|Entry.Module
CONTEXLA_INTEGRATION_PACKAGES  optional semicolon-separated ebin|Entry.Module
```

Generate `SECRET_KEY_BASE` during deployment. Do not reuse it across customer
installations. Package paths must be absolute and point to controlled,
checksum-verified package contents.

## First installation

Run these commands from the extracted release directory. On Windows use
`bin\contexla.bat`; on Unix use `bin/contexla`.

1. Configure `DATABASE_URL`, `SECRET_KEY_BASE`,
   `CONTEXLA_ARTIFACTS_PATH`, and any curated package registrations.
2. Apply platform and registered Application migrations:

   ```powershell
   .\bin\contexla.bat eval "Contexla.Release.migrate_all()"
   ```

3. Bootstrap the one initial administrator from a unique temporary password:

   ```powershell
   $env:CONTEXLA_ADMIN_EMAIL = "admin@example.org"
   $env:CONTEXLA_ADMIN_PASSWORD = "a unique temporary password"
   .\bin\contexla.bat eval "Contexla.Release.bootstrap_admin()"
   Remove-Item Env:CONTEXLA_ADMIN_PASSWORD
   ```

   Bootstrap refuses to run once any user exists. The administrator must change
   the temporary password at first login.
4. Run bounded diagnostics:

   ```powershell
   .\bin\contexla.bat eval "Contexla.Release.diagnostics()"
   ```

5. Set `PHX_SERVER=true` and start the release under the host's service manager.
6. Verify `/health/live`, `/health/ready`, login, and the installed Application
   definitions expected for that customer distribution.

The serving process never runs migrations implicitly.

## Upgrade order

1. Verify a recoverable PostgreSQL and Artifact backup.
2. Stop traffic and stop the old release.
3. Retain the old release and exact trusted packages for rollback.
4. Install the new release and curated package versions without overwriting the
   old directory.
5. Apply the same runtime configuration and run `migrate_all/0`.
6. Run `diagnostics/0`, then start the serving process.
7. Verify health, authentication, Application definitions, and one bounded
   smoke action before restoring traffic.

Application Instances are pinned to an exact Application version. A new package
version does not silently repin existing Instances; an explicit compatibility
and upgrade mechanism is required before such an upgrade can be offered.

Database migrations may make binary rollback unsafe. Restore the coordinated
pre-upgrade backup when the release notes do not explicitly support database
downgrade.
