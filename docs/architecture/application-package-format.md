# Application package format

Contexla Applications are independently compiled trusted OTP packages. The SDK
builds a deterministic `.contexla-app` ZIP archive without requiring platform
source code.

```text
contexla-application.json
CHECKSUMS
lib/<otp-application>-<version>/
  ebin/*.beam
  ebin/*.app
  priv/repo/migrations/*.exs
  priv/static/*
```

The manifest declares the stable Application ID, semantic version, OTP
application, SDK entry module, SDK compatibility, owned PostgreSQL schema,
operations, and UI surfaces. Every regular entry except `CHECKSUMS` is covered by
a lower-case SHA-256 checksum. ZIP entry metadata is fixed so identical compiled
inputs produce identical package bytes and digest.

Build an Application from its independent Mix project:

```powershell
mix deps.get
mix test
mix contexla.application.package
```

Packages are trusted native code executing inside the Contexla VM. Checksums
prove identity and integrity, not safety. Only administrators may install trusted
packages.

## UI surface mount contract

Application surfaces run behind stable platform-owned routes and are rendered
dynamically through the platform surface controller. They are not mounted
directly in the Phoenix router, so the first argument supplied to LiveView
`mount/3` is not a reliable source of route/query values.

The platform supplies:

- `session["instance"]` for Instance surfaces;
- `session["actor_id"]` and `session["application_id"]` for new-Instance
  surfaces;
- `session["surface_params"]` for additional sanitized route/query values in
  both cases.

Application surfaces must read values such as a selected `run_id` from
`session["surface_params"]`. Platform routing identifiers are removed from that
map because the bounded Instance/Application context is already supplied
separately.

## Implementation status

The SDK builder and source-linked runtime loader are implemented. The production
installer still needs to validate archive paths, sizes, checksums, manifest/BEAM
identity, module collisions, SDK/Elixir/OTP compatibility, stage content-addressed
package files, and activate them only on controlled restart. It must feed the
same registry path used by source-linked development packages.
