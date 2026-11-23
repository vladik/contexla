# ADR 0023: Portfolio-led market development

Status: Accepted

Date: 2026-11-23

## Context

Contexla is being built by a small CMS-focused agency with limited outbound
sales capacity and no dependable stream of contracts from which every product
requirement can be extracted. Requiring a paid engagement before building any
Application prevents the portfolio from serving one of its primary purposes:
creating credible demonstrations, public content, and new sales conversations.

Digital Estate Assessment successfully proved the independent Application and
runtime architecture. Its current output has not demonstrated enough standalone
customer value to remain the commercial priority. Continuing to expand it
because it already exists would let sunk cost drive the portfolio.

## Decision

Contexla uses portfolio-led market development alongside paid validation.

- Every Application must be independently useful and have a recognizable job,
  concrete input and output, bounded first proof, promotable demonstration,
  commercial adjacency, and stop condition.
- A paid need is the strongest build signal, but a bounded market hypothesis
  grounded in observed problems and agency expertise may justify the first
  vertical slice before a contract exists.
- Applications are working product assets used to create demand as well as to
  deliver won work.
- Market-facing Solutions package outcomes, configuration, Integrations, and
  services; Solution is not a platform entity.
- Weak response to a completed demonstration is a reason to stop or reposition,
  not to add speculative features.
- Digital Estate Assessment is retained as an architecture proof and is no
  longer the active commercial priority.
- Content Integrity Monitor is the current first serious portfolio hypothesis.
  Its initial proof is generic and bounded to configured facts across
  JSON/CSV, HTTP JSON, and HTML representations with deterministic comparison,
  evidence, and Run history.

## Consequences

- Product documentation and roadmaps must distinguish implemented architecture
  proofs from active commercial priorities.
- Platform infrastructure still requires a current Application proof or
  strongly supported customer outcome; portfolio-led does not authorize broad
  speculative platform building.
- Content Integrity examples may use CMS, ERP, CRM, search, education, product,
  or multi-region scenarios, but those examples must not become hard-coded
  Application domains.
- The first Content Integrity proof excludes remediation, synchronization,
  accessibility certification, AI extraction, PDF/OCR, and broad vendor
  integration coverage.
- Agent-first architecture remains a requirement, while deterministic manual
  operation is completed before Agent operation or generated Processors.

This decision changes the current product priority established after ADR 0003.
ADR 0003 remains an accurate historical record of why Digital Estate Assessment
was the first implemented Application.
