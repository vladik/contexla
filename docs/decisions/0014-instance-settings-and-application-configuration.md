# ADR 0014: Platform Instance settings and Application configuration

Status: Accepted

Date: 2026-11-20

## Context

Every Application Instance has platform-owned identity such as its display name,
description, and navigation icon, while each Application owns domain configuration such as
assessment scope or validation policy. Treating both as one generic config map
would either couple the platform to Application domains or force Applications
to duplicate platform identity controls.

## Decision

Every Instance has a platform-owned General settings route at
`/applications/:instance_id/settings`. It manages the Instance icon override,
name, and description. When no icon override is selected, navigation uses the
installed Application's declared default icon.

Every Application package declares exactly one Instance settings surface with
`kind: settings`. That surface owns mutable domain configuration and is mounted
through the normal generic surface route. The General and Application settings
screens use the shared tab component so users experience one settings area
without crossing ownership boundaries.

An Application surface exposes the General settings route through an unselected
gear action in its contextual header. It is not a global-shell action and does
not use a sidebar-style tooltip. Application
configuration changes pass through the SDK runtime and the owning
Application's `validate_instance_config/1` callback.

## Consequences

- Platform identity and Application business configuration remain separate.
- Sidebar icons may distinguish multiple Instances of the same Application.
- Application packages must provide one settings surface even if their initial
  configuration is small.
- Existing Runs and evidence are not rewritten when future-run configuration
  changes.
- The icon picker is a shared UI component backed by a controlled icon set;
  arbitrary uploaded logos remain out of scope.
