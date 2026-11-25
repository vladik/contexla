# ADR 0012: Shared platform shell and independent UI package

Status: Accepted

Date: 2026-11-20

## Context

Contexla Applications are independently compiled OTP packages, but users should
experience one product rather than unrelated embedded tools. The platform must
provide consistent navigation, theming, accessibility, and presentation without
making Applications depend on concrete platform web modules.

Application templates may also contain Tailwind utilities that the platform
asset build does not scan. Relying on incidental classes emitted by platform
templates is not a valid package contract.

## Decision

The platform owns the authenticated outer shell, navigation, account controls,
global assets, and theme. A separate, independently compiled `contexla_ui`
package owns route-independent design tokens and domain-free components. Both
the platform and trusted Applications may depend on that package.

Applications own domain surfaces and optional namespaced assets. They do not
depend on `Contexla.Platform.Web`, reproduce the platform shell, or assume the platform
Tailwind build scans their source. Package-specific asset loading will be added
only when a real surface requires assets beyond the shared contract.

The source repository may scan the generic `applications/` directory for
source-linked development and curated builds. This does not name a concrete
Application and is not a substitute for the future installed-package asset
contract.

## Consequences

- Installed Applications look and behave like parts of one platform.
- The platform continues to compile and boot with zero concrete Applications.
- Shared components cannot use platform routes, repositories, authentication,
  or Application domains.
- Application authors have a smaller, stable UI vocabulary.
- Truly custom Application CSS or JavaScript requires an explicit package asset
  declaration and generic loader before it can be shipped.
- Shared UI changes require compatibility discipline because Applications may
  compile against an earlier UI package version.
