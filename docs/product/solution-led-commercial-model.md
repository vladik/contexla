# Solution-led commercial model

## Decision

Contexla is developed as a reusable commercial platform, but the initial
go-to-market motion is **solution-led, platform-backed, and service-assisted**.

Customers buy a defined business outcome such as a CMS estate assessment,
migration verification, or continuous accessibility assurance. They do not
initially buy a generic platform, an Application marketplace, or unrestricted
workflow-building technology.

Contexla remains a product asset rather than an internal collection of agency
scripts. It provides the repeatable execution, evidence, security, and extension
boundaries behind each solution. Its value may be monetized through assessment
fees, implementation projects, managed assurance, support, and eventually
licenses or subscriptions when demand supports them.

## Commercial hierarchy

```text
Customer problem and decision
        -> focused solution offer
        -> curated Contexla deployment
             platform runtime
             required Application(s)
             required Integration(s)
             required Capabilities and Processors
             customer configuration and Bindings
        -> evidence-backed consulting outcome
```

The architectural vocabulary is not the buyer-facing message:

- the **solution** is the scoped offer and outcome the customer buys;
- an **Application** is the durable business-domain implementation of that
  solution inside Contexla;
- an **Application Instance** is one configured customer use, such as an
  assessment of a college Drupal estate;
- Integrations, Capabilities, Processors, and Bindings supply the reusable and
  customer-specific operations required by that Instance.

## Positioning rule

Lead sales and marketing with the recognized problem, trigger, decision, and
deliverable. Explain Contexla second as the reason the agency can deliver the
work with stronger evidence, repeatability, adaptability, and customer control.

For example, prefer:

> Understand the Drupal estate you operate before approving an upgrade,
> migration, or vendor change.

over:

> Install an extensible agent-first digital-content automation platform.

Technical architecture remains important for security, architecture,
procurement, and delivery stakeholders, but it is not the initial demand
message.

## Initial delivery modes

Use the least-friction mode that satisfies the engagement:

1. **Snapshot-supported service** — the customer runs an approved collector or
   supplies bounded exports; the agency operates Contexla in an agreed secure
   environment and returns the assessment deliverables.
2. **Customer-hosted engagement** — Contexla runs in the customer's environment
   when evidence cannot leave it or policy requires local execution.
3. **Ongoing assurance** — Contexla remains deployed for monitoring,
   verification, evidence retention, and periodic expert review when a repeated
   need has been proven.

On-premise capability is a commercial advantage, not a mandatory source of
deployment friction for every pilot. AI remains optional in all three modes.

## Distribution model

Early releases are curated solution distributions rather than a marketplace.
For example, a Digital Estate Assessment release may contain the platform,
Assessment Application, Drupal Integration, snapshot Collector, and only the
Capabilities and Processors required for the agreed scope.

Curated does not mean forked:

- customers run supported versions of the same platform and package code;
- customer differences live in configuration, Application Instances,
  Connections, Bindings, and bounded extension packages;
- customer-specific code never enters the platform core merely to finish an
  engagement;
- supported package combinations remain deliberately few;
- a distribution/assembly layer chooses packages without making the platform
  depend on concrete Applications.

Runtime package upload, a public marketplace, arbitrary compatibility
resolution, and self-service licensing are deferred until customers need to add
multiple solutions to existing installations.

## Consulting and revenue path

An independently useful Application or bounded service can be a responsible
entry point to larger work:

```text
qualified problem
    -> working demonstration or bounded pilot
    -> configured deployment or integration project
    -> implementation and support
    -> ongoing monitoring or operation
    -> expansion and referrals
```

The initial Application or deliverable must remain independently useful and
must not manufacture follow-on work.

Initial revenue can combine:

- fixed-scope assessment fees;
- paid custom Integration or Capability development;
- architecture and modernization planning;
- implementation and remediation projects;
- customer-hosted deployment and support;
- recurring managed assurance and review;
- licenses or subscriptions only when they improve an already validated buying
  motion.

## Productization rules

Contexla should make each engagement more repeatable without pretending expert
judgment can be eliminated.

- Standardize qualification, scope, evidence requests, collection, validation,
  interview guides, report structure, workshops, and follow-up planning.
- Automate acquisition, normalization, comparison, evidence linking, and
  deterministic checks before automating architectural judgment.
- Preserve clear expert authorship for conclusions that are not deterministic.
- Prefer configuration over custom code and bounded extensions over core
  changes.
- Never create a customer fork.
- Begin a customer-specific operation at Instance scope and promote it only
  after demonstrated reuse.
- Build another Application only when it has an independently useful outcome,
  a bounded promotable proof, agency adjacency, and a clear stop condition.
  Paid demand is strongest, but a disciplined portfolio hypothesis may justify
  the initial proof before a contract exists.
- Allow small standalone collectors, diagnostics, or lead-generation tools when
  forcing them into the platform would slow market learning. Promote successful
  operations into Contexla later.

## Build gate

Before implementing platform or package-lifecycle infrastructure, answer:

> Which current Application proof or strongly supported customer outcome
> requires this now?

If there is no concrete answer, defer the feature. In particular, do not build
a marketplace, universal workflow builder, autonomous planning system, broad
deployment matrix, or dynamic package ecosystem merely to make Contexla appear
more platform-like.

## Efficiency and validation metrics

Track business proof alongside software proof:

- qualified buyer conversations and their trigger events;
- engagement with a completed demonstration or public use case;
- conversion from conversation to a paid pilot, integration, or deployment;
- time from approved inputs to useful output;
- percentage of delivery reused without modification;
- new code and manual effort required per engagement;
- Findings or evidence that changed a customer action or decision;
- conversion to implementation, support, or ongoing operation;
- gross delivery margin and support load;
- reusable Integrations, Capabilities, and Processors produced by delivery.

The objective is not zero consulting. It is increasingly valuable consulting
with higher leverage, stronger evidence, reusable intellectual property, and a
credible path to recurring revenue.

