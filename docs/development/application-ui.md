# Application UI guide

Contexla Applications own their domain experience, but they do not invent a
new product shell or visual language. The shared UI package provides a small
set of composition patterns so independently developed Applications remain
recognizable, accessible, and efficient inside the platform.

This guide is a contract for hierarchy and interaction, not a requirement that
every Application have identical screens.

## Required surface hierarchy

Every Instance surface starts with `application_frame/1`:

```text
Application frame
  contextual header
    Application icon, Instance title, short purpose
    primary and contextual actions
  optional Application navigation
  scrollable content canvas
```

The frame supplies the stable alignment and overflow behavior. The Application
supplies the title, actions, navigation, and domain content. It must not render
the global sidebar, account controls, Agent workspace, or another full-page
layout.

```heex
<.application_frame
  id="inventory"
  icon="hero-archive-box"
  title={@instance.name}
  subtitle="Inventory and evidence"
  flash={assigns[:flash]}
>
  <:actions>
    <.button variant="primary">Start Run</.button>
  </:actions>
  <:navigation>
    <.tabs items={@tabs} />
  </:navigation>

  <.panel title="Inventory">...</.panel>
</.application_frame>
```

The `new` surface is the exception because an Instance does not exist yet. It
uses the base `surface/1` and shared `header/1`, then follows the same form
patterns as Instance surfaces.

## Proven page patterns

Choose the smallest pattern that fits the work:

| Pattern | Use it for | Shared composition |
| --- | --- | --- |
| Overview | Status, next action, recent Runs, key results | panels, stats, empty states |
| Collection | Searchable or filterable records | panel and table/list |
| List + detail | Selecting one record without losing collection context | `list_detail/1` |
| Sectioned editor | One record with several groups of fields | `form_layout/1`, `form_section/1` |
| Tabbed record | A few stable peer sections of one domain object | frame navigation and tabs |
| Run detail | Status, stages, evidence, failures, and retry actions | status, timeline/list, panels |
| Comparison | Source/target or before/after differences | table/list plus evidence links |
| Report | Readable evidence-backed output and export | header actions and report sections |
| Settings | Instance or Application configuration | tabs and sectioned editor |

Hierarchy + detail is a specialization of list + detail. Introduce a tree only
when the domain is genuinely hierarchical; do not make every inventory imitate
a CMS content tree.

Tabs are for stable peer sections, not every destination. A generated report,
wizard step, or record detail normally opens from its owning section. Do not
show navigation for functionality that has not been implemented.

## Forms and actions

Use a single readable field column by default. Group related fields with
`form_section/1` and place persistent form actions in the `form_layout/1`
actions slot. Put identity fields in this order:

1. icon;
2. name;
3. description;
4. domain-specific configuration.

Each surface should have one visually dominant action. Secondary actions use
neutral controls. Destructive actions require the shared confirmation modal.
Feedback uses the shared viewport toast rather than inline floating banners.

## States every surface must consider

An Application surface should deliberately render its relevant states:

- initial and empty;
- loading or queued;
- successful result;
- partial or warning;
- failed with a useful next action;
- permission denied or unavailable;
- narrow viewport and an open Agent workspace.

The Agent workspace reduces available width on desktop. Application layouts
must reflow instead of assuming a permanently wide canvas.

## Ownership rules

- Use `contexla_ui` components for domain-free presentation.
- Keep domain cards, result renderers, and event handling in the Application.
- Do not depend on `Contexla.Platform.Web`, platform repositories, or platform routes.
- Use `Contexla.Applications.Sdk.Runtime` for bounded platform services.
- Promote a component to shared UI only after unrelated surfaces demonstrate
  the same presentation need.

## Starting a new Application

Run the SDK generator from `applications/sdk`:

```powershell
mix contexla.application.new ..\my_application `
  --module Acme.MyApplication `
  --id com.acme.application.my-application `
  --name "My Application"
```

The generated project compiles independently, declares the mandatory new,
default, and settings surfaces, and demonstrates the frame, overview,
collection, and sectioned-form patterns. It is development scaffolding, not an
installed example Application and not a platform dependency.
