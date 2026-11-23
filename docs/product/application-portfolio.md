# Application portfolio

Applications are durable product modules that support commercial Solutions, not
menu labels for individual operations. Each should answer a recognizable
question and may own its own domain, tables, workers, UI, APIs, policies,
schedules, reports, and Adapters.

Application is primarily an architectural and product-boundary term. Initial
buyers are offered a focused outcome through a curated solution distribution,
not asked to assemble Applications from a marketplace. See the
[solution-led commercial model](solution-led-commercial-model.md).

## Current status and candidate portfolio

### Content Integrity Monitor - current portfolio hypothesis

Are important facts missing, stale, or inconsistent across authoritative
sources, CMS delivery, websites, APIs, search, and other representations?

The first proof is deliberately limited to configured facts across JSON/CSV,
HTTP JSON, and HTML. It detects and preserves evidence; it does not remediate or
synchronize content.

### Digital Estate Assessment - architecture proof, product investment paused

What exists in this content estate, how is it connected, and what creates cost,
risk, or migration complexity?

The implemented slice proved platform mechanics but has not demonstrated enough
standalone customer value to remain the commercial priority.

### Migration Readiness and Verification

What can be migrated, what needs human decisions, and did the target receive the
content correctly?

### Accessibility Monitor and Gate

Did accessibility regress, and does content satisfy required rules before it is
published?

### Content Transport

How can content be delivered reliably from a source to a controlled destination
with retries, manifests, receipts, and per-item evidence?

### Web History

What did a public page look like before, and what meaningfully changed?

## Portfolio discipline

An Application should be added only when its standalone job, demonstration,
bounded proof, and commercial relevance are explicit and implementation is
beginning. Evidence may be a paid need or a bounded market hypothesis grounded
in observed problems and agency expertise. Do not create empty OTP Applications
for the entire roadmap.

See [business intent and current priorities](business-intent-and-priorities.md)
for the selection test and current sequence.

Applications can share:

- platform authentication, navigation, scheduling, artifact storage, secrets,
  and observability;
- Clients and Connectors for external systems;
- stable Adapters where an Application-facing contract is genuinely shared;
- Capability contracts such as extraction, normalization, comparison,
  validation, transformation, and reporting, with replaceable Processor
  implementations.

They should not share generic domain tables merely to appear configurable.

