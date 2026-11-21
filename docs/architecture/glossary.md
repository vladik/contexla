# Glossary

These terms are normative within Contexla documentation and code. Product UI
may use friendlier labels, but it must not silently change their meaning.

## Application

A reusable, independently useful business Application installed in Contexla. An
Application owns its domain behavior and may own tables, workers, UI, APIs,
reports, and Application-specific Adapters. Digital Estate Assessment is the
first Application.

An Application is code and metadata, not a customer's configured assessment.

## Application Definition

The declarative platform-facing description of an Application: identity,
version, display information, configuration contract, operations, required
Adapter contracts, permissions, and compatibility.

## Application Instance

A configured use of an installed Application. `College Drupal Estate` is an
Instance of the Digital Estate Assessment Application. Instances own settings,
scope, bindings, and history; they do not duplicate Application code.

## Application Operation

A named command declared and implemented by an Application. An Operation is an
Application-facing unit such as running an assessment, evaluating a gate,
capturing a snapshot, or delivering a batch. It may orchestrate Capabilities and
normally produces an auditable Run when execution or evidence must be retained.

## Operation Invocation

One platform-owned audit record for calling a declared Application Operation.
It captures package and Operation identity, actor and approver, bounded input,
status, safe result/error metadata, and an optional link to an Application-owned
Run. It is not the Run itself and does not own Application domain results.

## Audit Event

One append-only platform record of a security or lifecycle-relevant action. It
identifies the actor, action, subject, optional Application Instance, time, and
bounded non-secret metadata. Audit Events complement domain Runs and
Invocations; they do not duplicate their inputs, outputs, or evidence.

## Trigger

The actor or condition that starts an Application Operation: human action, AI
agent, schedule, API request, webhook, external event, or authorized internal
event. Trigger does not imply a generic workflow builder.

## Solution

A commercial offering described on the website, in proposals, or during an
engagement. A Solution may combine one or more Applications, Integrations, and
professional services. Solution is not a Contexla package, registry, or database
entity.

## Run

One auditable execution of an operation for an Application Instance. A Run pins
the relevant input, configuration, Application/Adapter/Capability versions,
status, timestamps, results, and errors.

## Agent Session

An eventual auditable conversation or delegated task in which an agent plans,
investigates, requests approvals, and operates Contexla. An Agent Session may
inspect or start Application Runs but is not itself an authoritative Run and is
not Evidence.

## Integration Package

A controlled, versioned code package that lets Contexla acquire or interpret
data from an external system. It may provide Clients, Adapters, Connection
types, and related definitions. An Integration Package is installed platform-
wide and reused by Application Instances.

## Adapter

Contexla-side code that implements a stable contract consumed by an Application
or shared service. It coordinates Clients and translates system-native data
into structures that contract expects. It does not own unrelated Application
business decisions.

## Client

Low-level code for reading a snapshot or communicating with an external system.
It handles protocol details, authentication, pagination, rate limits, retries,
and source-native errors or identifiers.

## Connector

An optional component that runs in or near an external system to expose bounded
native data or events. The Drupal snapshot collector is a non-persistent
Connector: it runs near Drupal, collects approved metadata, writes a package,
and exits.

## Connection

A configured access or import source. A Connection contains non-secret settings
and references encrypted credentials when credentials are required. Multiple
Application Instances may bind to one Connection according to policy.

An uploaded offline snapshot is an import source and does not require a
persistent credentialed Connection.

## Capability

A stable, versioned semantic contract for a small executable operation: what it
does, the input/output/error schemas, allowed permissions, determinism, side
effects, and idempotency. It does not specify a programming language and is not
a complete business use case.

## Processor

One concrete, versioned implementation of a Capability. It declares runtime,
entrypoint, dependencies or package identity, implementation configuration,
requested permissions, timeout, and resource limits. Multiple Processors may
implement the same Capability contract.

## Capability Binding

The active selection of a Processor for a Capability at Platform, Application,
or Application Instance scope, including approved configuration and granted
permissions. Resolution prefers Instance, then Application, then Platform.

## Capability Invocation

One auditable execution of a Capability through a resolved Binding and exact
Processor version. It records actor, Application Instance, input, output or
error, status, and timestamps.

## Runner

Platform runtime infrastructure that executes a selected Processor according
to its runtime type and limits. A Runner is not a business Capability and is
not selected directly by an Application.

## Artifact

An immutable or versioned file-like output or input retained by Contexla, such
as a snapshot ZIP, extracted document, screenshot, machine-readable result, or
report. Artifacts have identity, integrity metadata, provenance, and retention
policy.

## Evidence

An Artifact, record, observation, or reference used to support an inventory
value, relationship, Finding, or decision. Evidence preserves provenance and is
not equivalent to an AI explanation.

## Finding

An Application-domain conclusion supported by Evidence. A Finding records its
origin, impact/severity, confidence, explanation, recommendation, status, and
review history. Deterministic and expert-authored Findings remain
distinguishable.

## Resource

A normalized entity in an Application's domain, such as a CMS installation,
site, environment, Drupal module, content type, integration, repository, or
database. Resource kinds evolve from real assessments rather than an exhaustive
upfront ontology.

## Relationship

A typed, directed connection between Resources, with provenance. Examples are
`contains`, `depends_on`, `uses`, `integrates_with`, and `deployed_to`.

