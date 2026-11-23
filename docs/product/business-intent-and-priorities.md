# Business intent and product priorities

This document is the canonical guide for deciding what Contexla should build
and why. Architecture documents define how the platform works; this document
defines the business role of the platform and its Application portfolio.

## Why Contexla exists

Contexla is a commercial product asset for a small CMS-focused agency. Its
first purpose is not to become a self-service SaaS marketplace or to replace
consulting revenue. Its purpose is to help the agency win and deliver broader
digital-content integration and automation work by demonstrating working,
reusable solutions rather than marketing only technology-specific skills such
as Sitecore or Drupal development.

The portfolio gives the agency:

- credible working demonstrations for the website, articles, LinkedIn, and
  sales conversations;
- reusable software that shortens delivery when a related project is won;
- differentiated intellectual property around content integration,
  monitoring, validation, migration, governance, and transport;
- a path from project work to implementation, support, managed operation, and
  eventually licensing or subscription where buyers support it;
- a platform on which a small team and AI coding agents can add focused
  functionality without rebuilding authentication, execution, evidence,
  packaging, operations, and UI foundations for every use case.

Contexla is therefore neither an internal consulting framework nor a product
that must initially succeed through license-only sales.

## Commercial hierarchy

```text
Recognizable customer problem
        -> market-facing Solution
             outcome, scope, configuration, integrations, and services
        -> one or more independently useful Contexla Applications
        -> shared platform, Integrations, Capabilities, and Processors
```

A Solution is how the agency packages and promotes an outcome. It is not a
runtime entity. An Application is reusable software and must provide useful
value when installed and used by itself. A Solution may initially use one
Application, and an Application may support several market-facing Solutions.

Applications must never be invented merely to make a consulting proposal look
product-backed. A consulting service also does not need a Contexla Application
when the work is primarily interviews, expert judgment, or one-off analysis.

## Portfolio-led market development

Contexla does not require an existing paid contract before every Application
can be built. That rule would defeat the purpose of using the portfolio to
create demand and win new kinds of work.

A bounded Application investment is justified when all of the following are
credible:

1. It addresses a recognizable and costly digital-content problem.
2. It is independently useful rather than only a component of a larger
   hypothetical Solution.
3. A small team can complete a convincing vertical slice.
4. It can be demonstrated without waiting for confidential customer data or a
   large enterprise integration.
5. The demonstration supports useful public content and a clear sales
   conversation.
6. It is adjacent to work the agency is qualified to deliver.
7. Its reusable domain and execution justify an Application rather than a
   standalone script, Capability, or consulting template.

Paid demand remains the strongest validation, but it is not the only permitted
starting signal. Observed market problems, the agency's delivery experience,
buyer conversations, public demonstrations, and bounded experiments may
justify an initial build. Market claims remain hypotheses until buyers confirm
them.

Every speculative portfolio build must be capped by a proof boundary. Complete
the smallest useful demonstration, publish and show it, then use buyer response
to decide whether to deepen, reposition, or stop. Weak response is not a reason
to add more features.

## Application selection test

Before starting an Application, answer:

- **Job:** What recurring job does it complete?
- **User:** Who operates it and who cares about its result?
- **Input:** What can a user reasonably provide or connect?
- **Output:** What concrete result, Finding, evidence, decision, or action does
  it produce?
- **Standalone value:** Why would it remain useful without another Application
  or consulting deliverable?
- **Demonstration:** Can the value be understood from a synthetic or public
  scenario in a few minutes?
- **Build boundary:** What is deliberately excluded from the first proof?
- **Revenue adjacency:** What projects, integrations, support, or ongoing
  operation could it credibly lead to?
- **Stop condition:** What evidence would show that further investment is not
  justified?

An Application that cannot answer these questions is not ready to build.

## Platform role

The platform supplies durable boundaries that are expensive and risky to
recreate for every solution:

- installation administration and authentication;
- independently installed Application packages and configured Instances;
- shared UI shell and Application surface contracts;
- Application Operation invocation, approval, audit, and Run linkage;
- Integration registration, Clients, Adapters, and Connections;
- Capability contracts, Processor selection, isolated execution, permissions,
  provenance, and invocation history;
- artifacts, evidence, durable jobs, operational diagnostics, and support
  boundaries;
- a context-aware Agent workspace that can eventually operate every installed
  Application through the same authoritative services as the UI and API.

The platform must remain unaware of concrete Applications and compile and boot
with none installed. Applications own their domain, tables, migrations,
workers, services, reports, and domain UI. Shared infrastructure is added only
when the current portfolio proof needs it or when reuse has been demonstrated.

## Agent-first direction

Agent-first does not mean chat-only, AI-dependent, or nondeterministic.
Contexla gives agents two distinct roles.

### Operate

An agent understands intent, inspects installed Applications, Operations,
Integrations, Connections, Capabilities, and evidence, proposes configuration,
requests approvals, invokes authorized Operations, monitors activity, and
explains stored results.

The structured Application UI remains authoritative for configuration, Runs,
Findings, evidence, and approvals. Manual UI and API operation must remain
available when no AI provider is allowed.

### Extend

When an operation is missing, an agent can help define a Capability contract or
create a Processor implementation with code, dependencies, tests, and a
manifest. Generated code begins at the narrowest useful scope, is treated as
untrusted, and executes only through the Capability runtime after validation
and approval.

The reliable platform owns authorization, execution, retries, validation,
evidence, and provenance. Agents supply adaptability, planning,
interpretation, configuration, and bounded generation. AI output is never the
source of truth.

The architecture must preserve this direction from the beginning, but a real
Application's deterministic workflow is implemented before autonomous agent
operation or generated Processors are added to it.

## Current portfolio decision

Digital Estate Assessment proved important platform mechanics: independent
packages, Application-owned data and migrations, generic surface mounting,
Operations, durable Runs, Artifacts, Adapters, Capability invocation, evidence,
Findings, reports, and operational support. Its current output has not shown
enough standalone customer value to justify further product investment.

It is retained as an architecture and integration proof. It is not the current
commercial priority and must not dictate platform or portfolio scope through
sunk cost.

The current first serious portfolio hypothesis is **Content Integrity
Monitor**:

> Detect when important content facts are missing, stale, or inconsistent
> across authoritative sources and delivered representations.

This is a horizontal Application, not a university-, Sitecore-, Drupal-, ERP-,
or CRM-specific product. Industry and system examples are demonstrations and
configured Instances, not domain assumptions in the Application.

The first proof should remain deliberately narrow:

```text
authoritative JSON or CSV
        -> configured entities and facts
        -> HTTP JSON and HTML representations
        -> deterministic extraction and normalization
        -> equality, missing, stale, and unavailable comparisons
        -> evidence-backed Findings and Run history
```

The first proof does not include automatic remediation, synchronization,
accessibility certification, arbitrary semantic comparison, AI extraction,
PDF/OCR, or a catalog of vendor-specific integrations. Those require separate
evidence.

Content Integrity is still a market hypothesis. Its first complete synthetic
demonstration must be used to test whether prospects understand the problem and
want a pilot, integration, deployment, or related project.

## Near-term priorities

1. Preserve the platform's package-neutral architecture and the completed
   foundation proofs.
2. Stop expanding Digital Estate Assessment unless it is needed as a technical
   fixture or a buyer specifically validates its standalone outcome.
3. Define the standalone Content Integrity product contract, buyer problem,
   demonstration, proof boundary, and stop condition before implementing it.
4. Build the smallest deterministic vertical slice using synthetic HTTP/JSON,
   HTML, and search/delivery representations.
5. Publish the working use case and use it in direct outreach and buyer
   conversations before broadening integrations or comparison behavior.
6. Add Agent operation only after the deterministic Application services and
   evidence model work manually.
7. Add an isolated or agent-generated Processor only when the proof exposes a
   real missing operation that cannot reasonably remain native.
8. Start another Application only when it passes the same standalone-value and
   bounded-portfolio tests.

## Decision discipline

When choosing between platform work, an Application feature, or a new
Application, prefer the action that creates the clearest completed and
promotable customer outcome. Do not confuse architectural completeness with
commercial progress, and do not confuse a broad long-term platform possibility
with the next proof.
