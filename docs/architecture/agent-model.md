# Agent model

AI agents play two distinct roles: they operate Contexla and extend Contexla.

## Operate the platform

An operating agent can:

1. understand user intent;
2. inspect installed Applications, Connections, Adapters, Capability contracts,
   and bound Processors;
3. determine whether the request is currently supported;
4. ask for missing configuration or explain how to acquire access;
5. propose a plan and configuration;
6. start authorized Runs;
7. inspect structured results and evidence;
8. summarize findings and suggest next actions.

Example:

```text
User: Audit our XYZ CMS.

Agent:
  - identifies Digital Estate Assessment;
  - checks for an Adapter that implements the estate-source contract;
  - checks for a usable Connection or snapshot import;
  - explains missing access or collection instructions;
  - creates an Application Instance after confirmation;
  - starts a deterministic assessment Run;
  - explains the evidence-backed findings.
```

If the system is unsupported, the agent should say precisely which layer is
missing. It may offer a snapshot format, integration instructions, or a proposal
to build a Client, Connector, or Adapter. It must not pretend that arbitrary
access can be generated safely from a prompt.

## Extend the platform

The agent first checks whether the required Capability contract exists. If the
contract exists but no suitable implementation is available, it creates a
Processor. If the semantic operation itself is new, a human or controlled
extension flow defines a new Capability contract and then a Processor.

```text
intent
  -> inspect registry
  -> identify missing Capability or missing Processor
  -> select/create Capability contract
  -> generate Processor package (manifest, code, dependencies, tests)
  -> create isolated environment
  -> validate contract, permissions, and tests
  -> execute against approved sample input
  -> human/policy approval
  -> register Processor version
  -> bind it at Instance, Application, or Platform scope
  -> invoke the Capability in an authorized Run
```

Generated customer-specific behavior starts at Instance scope. It is promoted
to Application or Platform scope only after review and demonstrated reuse. The
agent never calls generated code directly; the Capability runtime owns schema
validation, permission enforcement, execution, and provenance.

A missing system integration is not always a missing Capability. A new CMS may
require a Client, an Application-facing Adapter, and sometimes a Connector.
Those are larger, reviewed extension packages with explicit contracts and
lifecycle management.

## Authority boundaries

Agents are not the source of truth.

- Deterministic code owns collection, validation, comparison, policy, and gate
  decisions where correctness matters.
- Evidence must be retained independently of an agent's explanation.
- Agents cannot silently broaden permissions, reveal credentials, install
  unreviewed code in production, or change authoritative rules.
- Generated output must be traceable to model/provider, prompt/configuration,
  inputs, Capability contract, Processor version, and Binding when relevant.
- High-impact actions require explicit authorization or a pre-approved policy.

## No-AI mode

All essential functionality must remain available without an AI provider:

- administrators configure Connections and Application Instances manually;
- users start and inspect Runs through UI/API;
- deterministic reports and findings remain available;
- Capability contracts and Processors can be authored and registered by
  developers;
- the platform displays agent features as unavailable rather than degrading core
  execution.

This is necessary for on-premise customers with privacy, procurement, network,
or policy restrictions.

