# Application portfolio

Applications are commercial solutions, not menu labels for individual
operations. Each should answer a recognizable question and may own its own
domain, tables, workers, UI, APIs, policies, schedules, reports, and Adapters.

Application is primarily an architectural and product-boundary term. Initial
buyers are offered a focused outcome through a curated solution distribution,
not asked to assemble Applications from a marketplace. See the
[solution-led commercial model](solution-led-commercial-model.md).

## Near-term portfolio

### Digital Estate Assessment

What exists in this content estate, how is it connected, and what creates cost,
risk, or migration complexity?

### Migration Readiness and Verification

What can be migrated, what needs human decisions, and did the target receive the
content correctly?

### Accessibility Monitor and Gate

Did accessibility regress, and does content satisfy required rules before it is
published?

### Content Integrity

Do authoritative facts agree across CMS, website, API, PDF, ERP, and search?

### Content Transport

How can content be delivered reliably from a source to a controlled destination
with retries, manifests, receipts, and per-item evidence?

### Web History

What did a public page look like before, and what meaningfully changed?

## Portfolio discipline

An Application should be added only when there is evidence for the use case and
an implementation phase is beginning. Do not create empty OTP applications for
the entire roadmap.

Applications can share:

- platform authentication, navigation, scheduling, artifact storage, secrets,
  and observability;
- Clients and Connectors for external systems;
- stable Adapters where an Application-facing contract is genuinely shared;
- Capability contracts such as extraction, normalization, comparison,
  validation, transformation, and reporting, with replaceable Processor
  implementations.

They should not share generic domain tables merely to appear configurable.

