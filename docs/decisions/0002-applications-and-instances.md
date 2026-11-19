# Applications are reusable code; Instances are configured uses

Status: Accepted
Date: 2026-11-19

## Context

Contexla needs to run one solution repeatedly for different estates without
copying code or treating each engagement as a separate installation.

## Decision

An Application is installed reusable code plus a Definition. An Application
Instance is a configured use of that Application with scope, settings, bindings,
and Run history. Applications are installed once per Contexla installation and
may have many Instances.

## Consequences

- `Digital Estate Assessment` is an Application; `College Drupal Estate` is an
  Instance.
- Dynamic Application upload is not required initially; bundled Applications
  must still expose a stable Definition contract.
- Instance data cannot be stored in Application Definition metadata.

