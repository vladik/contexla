# Agent model

AI agents play two distinct roles: they operate Contexla and extend Contexla.

Executable extension rules are defined by the
[Tool architecture and runtime](tool-runtime.md).

The interaction model is Agent-first but not chat-only. Users express intent in
a persistent, context-aware Agent workspace while structured Application UI
remains authoritative for configuration, Runs, evidence, Findings, approvals,
and reports.

## Operate the platform

An operating agent can:

1. understand user intent;
2. inspect installed Applications, Connections, Adapters, and approved Tools;
3. determine whether the request is currently supported;
4. ask for missing configuration or explain how to acquire access;
5. propose a plan and configuration;
6. invoke authorized Application Operations and start their Runs;
7. inspect structured results and evidence;
8. summarize findings and suggest next actions.

Example:

```text
User: Monitor these product facts and tell me when the website or search index
      differs from the catalog API.

Agent:
  - identifies Content Integrity Monitor;
  - inspects its Operations and required Tools;
  - checks for usable source and representation Connections or imports;
  - proposes entity, fact, extraction, normalization, and comparison mappings;
  - explains unsupported sources or missing access precisely;
  - creates or updates an Application Instance after approval;
  - starts a deterministic integrity Run;
  - explains the evidence-backed findings.
```

If the system is unsupported, the agent should say precisely which layer is
missing. It may offer a snapshot format, integration instructions, or a proposal
to build a Client, Connector, or Adapter. It must not pretend that arbitrary
access can be generated safely from a prompt.

## Extend the platform

The agent first checks whether an installed, approved Tool performs the required
bounded operation. If no suitable Tool exists, the initial extension path is
AI-assisted development rather than autonomous production installation.

```text
intent
  -> inspect Tool registry
  -> identify one missing bounded operation
  -> ask for required behavior, schemas, permissions, and fixtures
  -> generate Tool Package (manifest, code, locked dependencies, tests)
  -> developer review and CI validation
  -> package/install through the supported delivery process
  -> administrator approval
  -> configure an exact Tool version for the Application Instance
  -> invoke it in an authorized Run
```

V1 expects AI-generated Tools to begin with Python and use one isolated virtual
environment per Tool version. A virtual environment isolates dependencies but
is not a security sandbox, so production Agents never silently install, enable,
replace, or execute generated code. The Tool Runtime owns schema validation,
permission enforcement, durable execution, and provenance.

A missing system integration is not always a missing Tool. A new CMS may
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
  inputs, exact Tool version/package checksum, and approval when relevant.
- High-impact actions require explicit authorization or a pre-approved policy.

## Agent workspace and context

The authenticated platform shell owns a persistent right-side Agent workspace.
It is available on platform and dynamically mounted Application surfaces and
shows its context explicitly:

```text
Platform
  -> Application Instance
  -> current Application surface
  -> optional Run, Finding, Resource, or Evidence item
```

The platform may derive platform, route, Application, and Instance context from
generic contracts. An Application may later contribute selected domain context
through a bounded SDK contract; the platform must not inspect an Application's
tables to construct prompts.

The workspace separates conversational interaction from activity monitoring:

- **Chat** accepts intent, questions, steering, and approvals;
- **Activity** presents plans, Operation calls, linked Runs, tool calls,
  approvals, failures, and completion state.

Closing the workspace must not cancel a durable Run. Agent Sessions and Runs
remain separate:

```text
Agent Session
  conversation, plan, investigation, approvals
       -> Application Operation
       -> Run (authoritative execution)
       -> Tool Invocation
```

The initial workspace shell intentionally displays AI as unconfigured. It does
not create fake messages, activity, approval counts, or execution records.

## No-AI mode

All essential functionality must remain available without an AI provider:

- administrators configure Connections and Application Instances manually;
- users start and inspect Runs through UI/API;
- deterministic reports and findings remain available;
- Tools can be authored, reviewed, packaged, and installed by developers;
- the platform displays agent features as unavailable rather than degrading core
  execution.

This is necessary for on-premise customers with privacy, procurement, network,
or policy restrictions.

