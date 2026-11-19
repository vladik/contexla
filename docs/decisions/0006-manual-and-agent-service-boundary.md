# Manual UI and agents use the same Application services

Status: Accepted
Date: 2026-11-19

## Context

Some enterprise installations cannot use an external AI provider. Allowing an
agent to become the workflow would make execution unavailable or unverifiable
without that agent.

## Decision

Applications expose authoritative services for configuration, execution,
queries, review, and reporting. Manual UI, API clients, and agents call those
same services and authorization boundaries. AI is optional and does not own
business state or deterministic decisions.

## Consequences

- The Drupal assessment must work end to end without AI.
- Agent actions are authorized and audited like equivalent human/API actions.
- Agents inspect persisted Resources, Findings, and Evidence rather than relying
  on untracked conversation analysis.
- UI-only business logic and agent-only execution paths are prohibited.

