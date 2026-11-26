# Contexla platform

The Phoenix host for Contexla authentication, generic Application routing,
package/runtime services, Artifacts, Tool execution, and the shared
authenticated shell.

The platform depends on the Application and Integration SDKs. It must compile
and boot without Digital Estate Assessment, Drupal, or any other concrete
package.

For local setup and source-linked package registration, see
[`docs/development/getting-started.md`](../docs/development/getting-started.md).
The default local URL is <http://localhost:4100>.

Registered Application migrations are explicit:

```powershell
mix ecto.migrate
mix contexla.platform.packages.migrate
```

Package discovery and platform startup never run Application-owned migrations
implicitly.

For production release construction, release-safe migration/bootstrap commands,
health probes, and backup/restore order, see
[`docs/operations/README.md`](../docs/operations/README.md).
