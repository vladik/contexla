# Module naming and file placement

Contexla uses repository-shaped module namespaces. A module name must make its
package type, package owner, and location apparent without searching the
repository.

This convention is intentional even though Elixir does not require module names
to match file paths. Contexla contains independently compiled Applications,
Tools, Integrations, Connectors, platform code, test infrastructure, and code
that may be generated with agent assistance. Predictable ownership is more
important here than minimizing module-name length.

## Namespace rule

Start every module with `Contexla`, then map the meaningful repository path to
PascalCase namespace segments:

```text
Contexla.<PackageCategory>.<PackageName>.<Folder>...<ModuleName>
```

Repository package categories keep the same singular or plural form used by
their top-level directory:

```text
applications -> Contexla.Applications
tools        -> Contexla.Tools
integrations -> Contexla.Integrations
connectors   -> Contexla.Connectors
platform     -> Contexla.Platform
```

Snake-case directory and file names become PascalCase module segments. Do not
replace a repository term with a shorter alias. In particular,
`content_integrity_monitor` becomes `ContentIntegrityMonitor`, not `Integrity`.

`lib` is the production compilation root and is not a namespace segment. Test
code includes the explicit `Test` segment so its purpose remains visible.
Generated build directories, dependencies, and private data directories such as
`_build`, `deps`, and `priv` do not define namespaces.

## Application examples

Production code:

```text
applications/content_integrity_monitor/lib/monitor.ex

Contexla.Applications.ContentIntegrityMonitor.Monitor
```

Nested production code:

```text
applications/content_integrity_monitor/lib/web/overview_live.ex

Contexla.Applications.ContentIntegrityMonitor.Web.OverviewLive
```

An Application-owned simulator:

```text
applications/content_integrity_monitor/test/simulators/external_http_source.ex

Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource
```

An Application test:

```text
applications/content_integrity_monitor/test/monitors/monitor_test.exs

Contexla.Applications.ContentIntegrityMonitor.Test.Monitors.MonitorTest
```

Application-specific fixtures, simulators, test helpers, and acceptance
infrastructure stay within that Application's `test` tree. Use a descriptive
folder such as `simulators`; do not hide runnable components in a generic
`support` directory. Extract code to a shared package only after reuse across
Applications is demonstrated and the shared contract is real.

## Other package examples

```text
tools/extract_json_value/lib/runtime.ex
-> Contexla.Tools.ExtractJsonValue.Runtime

integrations/sitecore/lib/client.ex
-> Contexla.Integrations.Sitecore.Client

connectors/drupal_snapshot/lib/collector.ex
-> Contexla.Connectors.DrupalSnapshot.Collector

platform/lib/tool_runtime/invocation.ex
-> Contexla.Platform.ToolRuntime.Invocation
```

Test modules for those packages insert `Test` after the package name or, for
the platform, after `Platform`:

```text
tools/extract_json_value/test/runtime_test.exs
-> Contexla.Tools.ExtractJsonValue.Test.RuntimeTest

platform/test/tool_runtime/invocation_test.exs
-> Contexla.Platform.Test.ToolRuntime.InvocationTest
```

## Enforcement

- New modules must follow this convention.
- Generators must produce this convention.
- Moving a module requires moving its file so both remain aligned.
- Manifests, runtime registries, supervision trees, and tests must use the full
  module name; do not introduce compatibility aliases as permanent APIs.
- Existing shorter namespaces are transitional. Refactor the affected package
  before adding substantial new functionality rather than expanding the old
  namespace.

Database schema names, table names, OTP application atoms, public IDs, and URL
paths are separate contracts. They do not change merely because an Elixir
module is renamed.
