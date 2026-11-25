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
  priv/static/*             # optional namespaced Application assets
```

The manifest declares the stable Application ID, semantic version, OTP
application, SDK entry module, SDK compatibility, owned PostgreSQL schema,
supported shared icon, operations, and UI surfaces. Every regular entry except `CHECKSUMS` is covered by
a lower-case SHA-256 checksum. ZIP entry metadata is fixed so identical compiled
inputs produce identical package bytes and digest.

The builder validates that identity, name, icon, version, OTP Application,
entry module, database schema, Operations, and surfaces agree with the compiled
Application definition. A package is rejected when its human-readable manifest
and executable contract disagree.

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

Every Application declares exactly one `new` surface, exactly one default
`instance` surface, and exactly one Instance surface with `kind: settings`.
The default is explicit metadata, not a required surface name:

```json
{"id":"overview","path":"overview","role":"instance","default":true}
```

The platform mounts that surface for the canonical URL
`/applications/:instance_id`. Named routes such as
`/applications/:instance_id/report` remain available. Platform navigation and
agents should use the canonical URL unless they intentionally target a named
surface.

The Application definition also declares one icon from the shared supported
icon vocabulary. The platform uses it for package and Instance navigation; the
Instance name remains the label and collapsed-navigation tooltip. An Instance
may store an icon override; absence of an override always falls back to the
Application icon.

The platform owns General Instance settings: icon override, display name, and
description. The
Application settings surface owns domain configuration and must update it
through bounded SDK services so `validate_instance_config/1` remains
authoritative.

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

The platform root layout supplies the authenticated shell, navigation, theme,
and global assets around every surface. Applications must not reproduce that
shell or depend on `Contexla.Platform.Web`. They may use the independently compiled
`contexla_ui` package for route-free components and semantic styling.

An Application must not assume the platform Tailwind build scans its source.
Most surfaces should use the shared UI contract. If an Application eventually
needs custom CSS or JavaScript, it owns compiled, namespaced files under
`priv/static` and declares them for the generic platform asset loader. That
declaration and loader are deferred until a real Application requires them.

## Implementation status

The SDK builder, compiled-definition identity validation, exact Instance version
guard, explicit Application migration task, and source-linked runtime loader are
implemented. Registered external OTP Applications are started with their
supervision trees. The production
installer still needs to validate archive paths, sizes, checksums, manifest/BEAM
module collisions, Elixir/OTP compatibility, stage content-addressed
package files, and activate them only on controlled restart. It must feed the
same registry path used by source-linked development packages.

This production lifecycle is deferred until a paid solution needs distributable
package installation. Early customer releases may be assembled from a curated,
tested package set by the Contexla delivery process. A public marketplace,
arbitrary package combinations, and self-service installation are separate
commercial capabilities and are not implied by this archive format.
