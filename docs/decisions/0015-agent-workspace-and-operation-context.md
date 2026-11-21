# ADR 0015: Agent workspace and Application Operation context

Status: Accepted

Date: 2026-11-21

## Context

Contexla Applications support different behaviors: one-time assessment,
recurring monitoring, synchronous gates, event-driven validation, durable
transport, archives, and investigation. Users should be able to work with an AI
agent without treating every behavior as a generic workflow or leaving the
Application surface they are inspecting.

## Decision

Application Operation is the common executable business command. Humans,
agents, schedules, APIs, webhooks, events, or authorized internal callers may
invoke an Operation. Auditable execution is retained as a Run; Capabilities and
Processors remain smaller implementation units used by Applications.

The authenticated platform shell owns a persistent right-side Contexla Agent
workspace with explicit platform or Application Instance context. It provides
separate Chat and Activity views and remains available around dynamically
mounted Application surfaces. The initial UI shows an honest unconfigured state
and contains no fake Agent execution.

Agent Sessions, Application Runs, and Capability Invocations remain distinct.
Closing the workspace does not define or control durable Run lifetime. Future
Application-specific context must enter through a bounded SDK contract rather
than platform access to Application tables.

## Consequences

- Applications with different invocation modes share one understandable model.
- Contexla does not need a generic visual workflow builder.
- The Agent experience remains in context like an IDE assistant rather than a
  disconnected chat page.
- Manual operation and no-AI installations remain first-class.
- Provider integration, session persistence, approvals, and tool execution are
  deliberately deferred until the agent-operated assessment proof.
