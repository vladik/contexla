# Contexla platform

The Phoenix host for Contexla authentication, generic Application routing,
package/runtime services, Artifacts, Capability execution, and the shared
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
mix contexla.packages.migrate
```

Package discovery and platform startup never run Application-owned migrations
implicitly.
