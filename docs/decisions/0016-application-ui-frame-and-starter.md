# Shared Application frame and independent starter

Status: Accepted
Date: 2026-11-21

## Context

Independent Applications need enough UI freedom to express different business
work, but unconstrained layouts produce inconsistent headers, navigation,
forms, and responsive behavior. Copying the first concrete Application would
also couple future packages to its domain and gradually make it an accidental
framework.

## Decision

Instance surfaces use a route-free `application_frame/1` from `contexla_ui`.
The frame owns contextual header, optional Application navigation, scrollable
canvas, and flash placement. Shared layout helpers cover only demonstrated
patterns such as sectioned forms and list/detail composition.

The Application SDK provides a generator for a separate Mix project that
declares the required package surfaces and demonstrates these shared patterns.
Generated Applications depend on the SDK and UI package, never on the platform
or a concrete Application. The starter is scaffolding and is not registered or
installed as a product package.

## Consequences

- Applications retain domain-specific workflows and components while sharing a
  recognizable product hierarchy.
- The platform still compiles and boots with zero concrete Applications.
- UI contract changes can be tested in the shared package and starter.
- New patterns are added only after a real Application demonstrates the need.
- Existing Applications may require small composition refactors when the shared
  contract evolves, but do not surrender ownership of their domain UI.
