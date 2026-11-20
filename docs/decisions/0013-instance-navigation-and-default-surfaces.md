# ADR 0013: Instance-first navigation and canonical default surfaces

Status: Accepted

Date: 2026-11-20

## Context

Application Instances are the configured solutions users operate day to day.
The platform previously listed Instances only on the Apps page and required
callers to know an Application-specific surface path such as `overview`. This
made navigation depend on package internals and left the canonical
`/applications/:instance_id` URL unresolved.

Applications also require different setup fields, so the platform cannot own a
universal Instance-configuration form without learning Application domains.

## Decision

The authenticated sidebar is Instance-first. It exposes a platform-owned New
Instance action, the configured Instances, and separate Apps and Settings
navigation. Instance links use only `/applications/:instance_id`; collapsed
navigation identifies each Instance through its Application icon and an
Instance-name tooltip.

Every Application definition and package manifest declares a supported icon,
exactly one `new` surface, and exactly one default `instance` surface. The
platform resolves the canonical Instance URL to that default surface. Named
surface routes remain available for reports, settings, findings, and other
Application-owned screens.

The New Instance flow is split at the package boundary: the platform lets the
user choose an installed Application, then mounts that Application's declared
`new` surface. The Application owns all domain-specific configuration and
creates the Instance through the SDK runtime.

## Consequences

- Users navigate by configured solution rather than internal surface names.
- Agents and external links have a stable canonical Instance URL.
- Application authors may call the home surface `overview`, `dashboard`, or a
  domain-specific name; they mark it as default instead of naming it `index`.
- Packages without one setup surface and one default Instance surface are
  rejected by the SDK contract.
- The platform sidebar remains independent of concrete Application code.
- A future package installer belongs on the Apps screen, but is not implied by
  the current source-linked package list.
