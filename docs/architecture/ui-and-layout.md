# UI and layout architecture

Contexla presents independently compiled Applications as one coherent product.
The platform supplies a stable visual shell and design system; Applications
supply domain-specific surfaces inside that system.

## Ownership boundary

```text
Platform
  authenticated shell
  dedicated authentication and public error layouts
  navigation and account controls
  global theme and asset pipeline
  generic Application routes and surface mounting

Contexla UI package
  semantic design tokens
  route-independent, domain-free components
  surface layout vocabulary

Application
  domain LiveViews and LiveComponents
  domain forms, tables, reports, and workflows
  optional namespaced assets when shared UI is insufficient
```

The platform must not compile against a concrete Application. An Application
must not depend on `ContexlaWeb` or platform routes. Both may depend on the
independently compiled `contexla_ui` package.

## Surface contract

An Application surface is content hosted by Contexla, not a separate website.
It must not reproduce the platform logo, account navigation, global sidebar,
theme controls, or full-page shell. The platform root layout surrounds both
platform pages and dynamically mounted Application LiveViews.

Surfaces should use shared components for page width, page headers, panels,
actions, tables, fields, empty states, statuses, and statistics. Domain-specific
components remain in the owning Application and call Application services rather
than platform repositories.

The authenticated composition has three stable levels:

```text
Platform shell
  global sidebar + breadcrumb bar
    Application surface
      contextual title/action header
        scrollable content canvas
```

Do not flatten these levels into one padded document. Authentication, 404, and
500 pages use dedicated public layouts and must never appear inside the
authenticated sidebar shell.

The global sidebar is Instance-first:

```text
Brand and collapse control
New instance
Configured Application Instances
Apps
Settings
User, theme, and logout controls
```

The platform obtains Instance names and Application icons through generic
registry and Instance contracts. Each Instance links to its canonical bare URL;
the owning Application's default surface is resolved at runtime. In collapsed
mode the Instance name must remain available as a side tooltip. Application
sub-navigation belongs inside the Application surface, not in package-specific
platform code.

An active Instance's Application surface exposes a platform-owned settings gear
in the right side of its contextual header. The gear is an unselected action,
not a persistent navigation state, and therefore has no highlighted background
or sidebar-style tooltip. Its settings area
uses shared tabs to separate General identity settings from the
Application-owned configuration surface. General settings include the Instance
icon override, name, and description in that order. The compact shared icon
picker limits selection to the host-supported icon vocabulary, closes after a
selection, and preserves the Application icon as the default. New-Instance
forms use the same identity-field order.

Applications should use the shared tab component for a small number of stable
peer sections such as Overview, Inventory, Findings, and Runs. Detail screens
such as one generated report should normally be reached from their owning
section rather than becoming permanent primary tabs. Add a tab only when its
backing functionality exists.

Below the desktop breakpoint the same sidebar becomes a modal navigation
drawer with an explicit opener, close control, backdrop, and Escape handling.
Do not create a separate mobile navigation model that can drift from the
desktop Instance list.

The platform breadcrumb reflects generic platform context: Apps, New instance,
Settings, Account settings, or the active Instance name. It does not interpret
Application-specific surface semantics; those belong in the contextual surface
header and optional Application-owned tabs.

The contextual surface composition is a shared contract, not a suggestion:

```text
Surface root       flex column, full available height, overflow hidden
Context header     surface background, bottom border, px-4/sm:px-6, py-4
Content canvas     independently scrollable, p-4/sm:p-6
Card               rounded-2xl, one-pixel border, p-5/sm:p-6
```

Use the shared `Header` directly inside the surface header slot. Titles,
subtitles, and action controls belong to its defined regions. Do not create a
second page-header abstraction, add an extra padded wrapper around it, or place
navigation links above the title; those variations break alignment between
platform and Application surfaces. Back navigation, downloads, and other page
actions belong in the header action region.

Flash feedback is rendered as a viewport-level toast stack in the lower logical
end corner. It must not participate in an Application's document flow or inherit
the surface width. Destructive actions use the shared confirmation modal pattern.

The initial shared component set includes Button, Input, Header, Table, List,
Tabs, Modal, Tooltip, Icon, Avatar, and surface composition helpers. Extend these
components when a common presentation need appears; do not create parallel
Application-local buttons, inputs, modals, tables, or shell implementations.

## Visual vocabulary

Shared CSS uses semantic tokens rather than product- or domain-specific colors:

```text
bg, surface, surface-raised
border, border-strong
text, text-muted, text-subtle
primary, accent
success, warning, danger, info
```

Light and dark themes change token values, not Application markup. Accessible
focus states, reduced-motion behavior, spacing, typography, and responsive shell
behavior are platform concerns.

The operational visual rules are intentionally narrow:

- compact controls and dense management lists;
- 14px primary surface radius and one-pixel hairline borders;
- violet for active state and primary action, ember as a limited accent;
- one dominant action per surface;
- neutral surfaces for all secondary actions;
- slow, structural motion only;
- collapsible platform navigation with optional secondary and detail panels.

The initial visual language uses a restrained violet-to-ember accent, neutral
operational surfaces, hairline borders, compact controls, and a collapsible
platform shell. Domain concepts must never leak into shared presentation.

## Browser assets

The platform bundle includes the shared tokens, shell styles, shared component
styles, icons, and core hooks. Tailwind scans `contexla_ui` so its static class
vocabulary is always present.

During source-linked development and curated monorepo release assembly, the
platform asset build also scans the generic `applications/` source directory.
This keeps the current proof visually complete without naming a concrete
Application in platform code. It is a build-time convenience, not the installed
package contract.

Applications should normally need no custom browser assets. When a domain
surface needs styles or hooks that cannot be expressed through the shared UI,
the Application owns and packages compiled, namespaced assets under
`priv/static`. Those assets must be declared by the package and loaded through a
generic platform asset mechanism; they must not redefine global tokens or rely
on the platform Tailwind build scanning Application source.

The package-declared asset loading mechanism is not implemented yet. Until it
is required, first-party surfaces should prefer shared components; curated
builds may include their remaining utilities through the generic source scan.
This limitation is explicit so source-linked development does not accidentally
become the production asset design.

## Component placement

Use these tests before creating a component:

```text
Used across unrelated Applications and domain-free? -> contexla_ui
Owns platform navigation, identity, or routes?       -> platform
Expresses an Application domain concept?             -> Application
Needs independent events/state?                      -> LiveComponent
Presentation only?                                   -> function component
```

Shared components must not access `Contexla.Repo`, storage clients, Application
contexts, or platform authentication. Application UI must use its public domain
services and bounded SDK runtime services.

## Evolution rule

Start a component in the narrowest correct owner. Promote it to `contexla_ui`
only after reuse across unrelated surfaces is demonstrated. A consistent design
system does not require turning domain presentation into generic components.
