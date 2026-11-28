defmodule Contexla.Platform.Web.Layouts do
  @moduledoc "Platform-owned public and authenticated layouts."
  use Contexla.Platform.Web, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    <Contexla.Ui.ContexlaUi.Components.UI.Toast.toast flash={@flash} id="platform-toast-group" />
    """
  end

  @doc "Renders the platform-owned authenticated shell."
  attr :current_scope, :map, required: true
  attr :current_path, :string, default: "/"
  attr :instances, :list, default: []
  slot :inner_block, required: true

  def platform_shell(assigns) do
    ~H"""
    <div
      id="contexla-platform-shell"
      class="relative flex h-dvh min-h-dvh overflow-hidden bg-bg text-text"
    >
      <button
        id="app-sidebar-backdrop"
        type="button"
        data-mobile-sidebar-close
        class="fixed inset-0 z-40 hidden bg-[#0F1330]/45 backdrop-blur-[2px] md:hidden"
        aria-label="Close navigation"
      />
      <aside id="app-sidebar" class="shell-sidebar h-dvh" data-sidebar-root>
        <div class="flex shrink-0 items-center gap-1 px-2.5 py-2.5" data-sidebar-header>
          <a
            href="/applications"
            data-sidebar-row
            data-tooltip="Contexla — Digital Content Integration and Automation Platform"
            data-tooltip-position="side"
            class="flex min-w-0 flex-1 items-center gap-2 rounded-xl px-1.5 py-1 transition-colors hover:bg-surface"
          >
            <.brand_mark class="size-7 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1">
              <strong class="block truncate text-xs font-semibold leading-tight text-text">Contexla</strong>
              <span class="block truncate text-[10px] leading-tight text-text-muted">
                Content automation
              </span>
            </span>
          </a>
          <button
            type="button"
            data-sidebar-collapse
            data-tooltip="Collapse navigation"
            data-tooltip-position="side"
            class="hidden size-7 shrink-0 place-items-center rounded-lg text-text-muted transition-colors hover:bg-surface hover:text-primary md:grid"
            aria-label="Collapse navigation"
            aria-expanded="true"
          >
            <span data-sidebar-collapse-icon><.icon name="hero-chevron-left" class="size-3.5" /></span>
            <span data-sidebar-expand-icon><.icon name="hero-chevron-right" class="size-3.5" /></span>
          </button>
          <button
            type="button"
            data-mobile-sidebar-close
            class="grid size-7 shrink-0 place-items-center rounded-lg text-text-muted transition-colors hover:bg-surface hover:text-primary md:hidden"
            aria-label="Close navigation"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </div>

        <nav
          class="min-w-0 flex-1 overflow-x-hidden overflow-y-auto pb-2"
          aria-label="Platform navigation"
        >
          <a
            href="/applications/new"
            data-sidebar-row
            data-tooltip="New Application Instance"
            data-tooltip-position="side"
            aria-current={if String.starts_with?(@current_path, "/applications/new"), do: "page"}
            class={nav_item_class(String.starts_with?(@current_path, "/applications/new"))}
          >
            <.icon name="hero-plus" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">New Instance</span>
          </a>

          <p
            :if={@instances != []}
            class="px-4 pb-1 pt-3 text-[9px] font-semibold uppercase tracking-[0.18em] text-text-muted"
            data-sidebar-expanded
          >
            Instances
          </p>

          <a
            :for={instance <- @instances}
            href={"/applications/#{instance.id}"}
            data-sidebar-row
            data-tooltip={instance.name}
            data-tooltip-position="side"
            aria-current={if instance_active?(@current_path, instance.id), do: "page"}
            class={nav_item_class(instance_active?(@current_path, instance.id))}
          >
            <span class="grid size-6 shrink-0 place-items-center">
              <.icon name={instance.icon} class="size-4" />
            </span>
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">{instance.name}</span>
          </a>

          <p
            class="px-4 pb-1 pt-3 text-[9px] font-semibold uppercase tracking-[0.18em] text-text-muted"
            data-sidebar-expanded
          >
            Platform
          </p>

          <a
            href="/connections"
            data-sidebar-row
            data-tooltip="Connections"
            data-tooltip-position="side"
            aria-current={if @current_path == "/connections", do: "page"}
            class={nav_item_class(@current_path == "/connections")}
          >
            <.icon name="hero-link" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">Connections</span>
          </a>

          <a
            href="/applications"
            data-sidebar-row
            data-tooltip="Applications"
            data-tooltip-position="side"
            aria-current={if applications_active?(@current_path), do: "page"}
            class={nav_item_class(applications_active?(@current_path))}
          >
            <.icon name="hero-squares-2x2" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">Applications</span>
          </a>

          <a
            :if={@current_scope.user.role == :admin}
            href="/operations"
            data-sidebar-row
            data-tooltip="Operations"
            data-tooltip-position="side"
            aria-current={if @current_path == "/operations", do: "page"}
            class={nav_item_class(@current_path == "/operations")}
          >
            <.icon name="hero-command-line" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">Operations</span>
          </a>

          <a
            href="/settings"
            data-sidebar-row
            data-tooltip="Settings"
            data-tooltip-position="side"
            aria-current={if @current_path == "/settings", do: "page"}
            class={nav_item_class(@current_path == "/settings")}
          >
            <.icon name="hero-cog-6-tooth" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">Settings</span>
          </a>
        </nav>

        <div class="shrink-0 border-t border-border px-3 py-2">
          <div class="flex items-center gap-2" data-sidebar-footer>
            <a
              href={~p"/users/settings"}
              data-tooltip={@current_scope.user.email}
              data-tooltip-position="side"
              class="flex min-w-0 flex-1 items-center gap-2"
            >
              <span class="grid size-7 shrink-0 place-items-center rounded-lg bg-surface text-xs font-semibold text-text-muted">
                {@current_scope.user.email |> String.first() |> String.upcase()}
              </span>
              <span
                data-sidebar-expanded
                class="min-w-0 flex-1 truncate text-xs font-medium text-text"
              >
                {@current_scope.user.email}
              </span>
            </a>

            <details data-sidebar-expanded data-theme-menu class="group relative shrink-0">
              <summary
                class="grid size-7 list-none place-items-center rounded-lg text-text-muted transition-colors hover:bg-surface hover:text-text [&::-webkit-details-marker]:hidden"
                aria-label="Color theme"
                data-tooltip="Color theme"
                data-tooltip-position="side"
              >
                <.icon name="hero-swatch" class="size-3.5" />
              </summary>
              <div class="absolute bottom-full end-2 z-50 mb-2 min-w-32 overflow-hidden rounded-xl border border-border bg-surface p-1.5 shadow-xl">
                <button
                  type="button"
                  data-theme-choice="light"
                  class="flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-xs font-medium text-text-muted hover:bg-surface-raised hover:text-text"
                >
                  <.icon name="hero-sun" class="size-3.5" /> Light
                </button>
                <button
                  type="button"
                  data-theme-choice="dark"
                  class="flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-xs font-medium text-text-muted hover:bg-surface-raised hover:text-text"
                >
                  <.icon name="hero-moon" class="size-3.5" /> Dark
                </button>
              </div>
            </details>

            <.link
              href={~p"/users/log-out"}
              method="delete"
              data-tooltip="Log out"
              data-tooltip-position="side"
              class="grid size-7 shrink-0 place-items-center rounded-lg text-text-muted transition-colors hover:bg-surface hover:text-red-600"
            >
              <.icon name="hero-arrow-right-start-on-rectangle" class="size-3.5" />
            </.link>
          </div>
        </div>
      </aside>

      <main class="flex min-w-0 flex-1 flex-col overflow-hidden bg-bg">
        <header class="flex h-14 shrink-0 items-center gap-2 border-b border-border bg-surface px-3 sm:px-4">
          <button
            type="button"
            data-mobile-sidebar-open
            class="grid size-9 shrink-0 place-items-center rounded-xl text-text-muted transition-colors hover:bg-surface-raised hover:text-text md:hidden"
            aria-label="Open navigation"
            aria-controls="app-sidebar"
            aria-expanded="false"
          >
            <.icon name="hero-bars-3" class="size-5" />
          </button>
          <a href="/applications" class="flex items-center gap-2 md:hidden">
            <.brand_mark class="size-7" />
            <strong class="text-sm">Contexla</strong>
          </a>
          <nav
            aria-label="Breadcrumb"
            class="hidden min-w-0 flex-1 items-center gap-1.5 text-sm md:flex"
          >
            <a href="/applications" class="shrink-0 text-text-muted transition-colors hover:text-text">
              Contexla
            </a>
            <%= for {item, index} <- Enum.with_index(breadcrumbs(@current_path, @instances)) do %>
              <span class="shrink-0 text-border-strong">/</span>
              <a
                :if={item.href && index < length(breadcrumbs(@current_path, @instances)) - 1}
                href={item.href}
                class="max-w-52 shrink-0 truncate text-text-muted transition-colors hover:text-text"
              >
                {item.label}
              </a>
              <span
                :if={!item.href || index == length(breadcrumbs(@current_path, @instances)) - 1}
                class="truncate font-medium text-text"
                aria-current="page"
              >
                {item.label}
              </span>
            <% end %>
          </nav>
          <div class="min-w-0 flex-1 md:hidden" />
          <button
            type="button"
            data-agent-workspace-toggle
            class="grid size-9 shrink-0 place-items-center rounded-xl text-text-muted transition-colors hover:bg-surface-raised hover:text-primary"
            aria-label="Open Contexla Agent"
            aria-controls="agent-workspace"
            aria-expanded="false"
          >
            <.icon name="hero-sparkles" class="size-5" />
          </button>
        </header>

        <div class="flex-1 overflow-y-auto">
          {render_slot(@inner_block)}
        </div>
      </main>
      <.agent_workspace current_path={@current_path} instances={@instances} />
      <button
        id="agent-workspace-backdrop"
        type="button"
        data-agent-workspace-close
        class="fixed inset-0 z-40 hidden bg-[#0F1330]/45 backdrop-blur-[2px] lg:hidden"
        aria-label="Close Contexla Agent"
      />
    </div>
    """
  end

  @doc "Renders the platform-owned Agent workspace shell."
  attr :current_path, :string, required: true
  attr :instances, :list, required: true

  def agent_workspace(assigns) do
    assigns = assign(assigns, :context, agent_context(assigns.current_path, assigns.instances))

    ~H"""
    <aside
      id="agent-workspace"
      data-agent-workspace
      data-instance-id={@context[:instance_id]}
      class="agent-workspace"
      aria-label="Contexla Agent"
      aria-hidden="true"
      inert
    >
      <div class="agent-workspace-inner">
        <header class="flex h-14 shrink-0 items-center gap-3 border-b border-border px-4">
          <span class="grid size-8 shrink-0 place-items-center rounded-xl bg-primary-subtle text-primary">
            <.icon name="hero-sparkles" class="size-4" />
          </span>
          <div class="min-w-0 flex-1">
            <h2 class="truncate text-sm font-semibold text-text">Contexla Agent</h2>
            <p class="truncate text-[11px] text-text-muted">AI workspace</p>
          </div>
          <button
            type="button"
            data-agent-workspace-close
            class="grid size-8 shrink-0 place-items-center rounded-lg text-text-muted transition-colors hover:bg-surface-raised hover:text-text"
            aria-label="Close Contexla Agent"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </header>

        <div class="border-b border-border px-3 pt-2">
          <div class="flex gap-1" role="tablist" aria-label="Agent workspace views">
            <button
              id="agent-chat-tab"
              type="button"
              role="tab"
              data-agent-tab="chat"
              aria-controls="agent-chat-view"
              aria-selected="true"
              class="agent-workspace-tab is-active"
            >
              <.icon name="hero-chat-bubble-left-right" class="size-3.5" /> Chat
            </button>
            <button
              id="agent-activity-tab"
              type="button"
              role="tab"
              data-agent-tab="activity"
              aria-controls="agent-activity-view"
              aria-selected="false"
              class="agent-workspace-tab"
            >
              <.icon name="hero-queue-list" class="size-3.5" /> Activity
            </button>
          </div>
        </div>

        <div class="border-b border-border bg-surface-raised/60 px-4 py-3">
          <div class="mb-1.5 flex items-center justify-between gap-2">
            <span class="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-muted">
              Current context
            </span>
            <span class="rounded-full bg-surface px-2 py-0.5 text-[10px] font-medium text-text-muted">
              {@context.level}
            </span>
          </div>
          <div class="flex items-center gap-2.5">
            <span class="grid size-8 shrink-0 place-items-center rounded-lg border border-border bg-surface text-primary">
              <.icon name={@context.icon} class="size-4" />
            </span>
            <div class="min-w-0">
              <p class="truncate text-xs font-semibold text-text">{@context.title}</p>
              <p class="truncate text-[11px] text-text-muted">{@context.area}</p>
            </div>
          </div>
        </div>

        <section
          id="agent-chat-view"
          role="tabpanel"
          aria-labelledby="agent-chat-tab"
          data-agent-view="chat"
          class="flex min-h-0 flex-1 flex-col"
        >
          <div class="flex flex-1 items-center justify-center overflow-y-auto p-6 text-center">
            <div class="max-w-64">
              <span class="mx-auto grid size-11 place-items-center rounded-2xl border border-border bg-surface-raised text-text-muted">
                <.icon name="hero-cpu-chip" class="size-5" />
              </span>
              <h3 class="mt-3 text-sm font-semibold text-text">AI is not configured</h3>
              <p class="mt-1.5 text-xs leading-5 text-text-muted">
                Contexla Applications and manual Operations remain available. When an approved AI provider is configured, this workspace will help operate the current context.
              </p>
            </div>
          </div>
          <div class="shrink-0 border-t border-border p-3">
            <label for="agent-prompt" class="sr-only">Ask Contexla Agent</label>
            <div class="rounded-xl border border-border bg-surface-raised p-2">
              <textarea
                id="agent-prompt"
                rows="3"
                disabled
                placeholder="Ask about this context or delegate a task..."
                class="block w-full resize-none border-0 bg-transparent px-1.5 py-1 text-sm text-text outline-none placeholder:text-text-muted disabled:cursor-not-allowed disabled:opacity-70"
              />
              <div class="mt-1 flex items-center justify-between gap-2">
                <span class="px-1 text-[10px] text-text-muted">Provider required</span>
                <button
                  type="button"
                  disabled
                  class="grid size-8 place-items-center rounded-lg bg-primary text-white opacity-45"
                  aria-label="Send message"
                >
                  <.icon name="hero-arrow-up" class="size-4" />
                </button>
              </div>
            </div>
          </div>
        </section>

        <section
          id="agent-activity-view"
          role="tabpanel"
          aria-labelledby="agent-activity-tab"
          data-agent-view="activity"
          data-agent-activity
          class="flex min-h-0 flex-1 flex-col overflow-y-auto"
          hidden
        >
          <div data-activity-items class="divide-y divide-border" aria-live="polite"></div>
          <div data-activity-empty class="flex flex-1 items-center justify-center p-6 text-center">
            <div class="max-w-64">
              <span class="mx-auto grid size-11 place-items-center rounded-2xl border border-border bg-surface-raised text-text-muted">
                <.icon name="hero-queue-list" class="size-5" />
              </span>
              <h3 class="mt-3 text-sm font-semibold text-text">No recent activity</h3>
              <p class="mt-1.5 text-xs leading-5 text-text-muted">
                Operation invocations for this context will appear here.
              </p>
            </div>
          </div>
        </section>
      </div>
    </aside>
    """
  end

  attr :class, :any, default: nil

  def brand_mark(assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 32 32" role="img" aria-label="Contexla">
      <rect x="2" y="2" width="28" height="28" rx="9" fill="#5842F6" />
      <path
        d="M21.5 10.25A7.5 7.5 0 1 0 21.5 21.75"
        fill="none"
        stroke="white"
        stroke-width="2.8"
        stroke-linecap="round"
      />
      <path
        d="M19 12.5L23 16L19 19.5"
        fill="none"
        stroke="#FF8068"
        stroke-width="2.4"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <Contexla.Ui.ContexlaUi.Components.UI.Toast.toast flash={@flash} id={@id} />
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="flex items-center rounded-xl border border-border bg-surface-raised p-1">
      <button
        type="button"
        data-theme-choice="light"
        class="rounded-lg px-3 py-1.5 text-xs text-text-muted"
      >Light</button>
      <button
        type="button"
        data-theme-choice="dark"
        class="rounded-lg px-3 py-1.5 text-xs text-text-muted"
      >Dark</button>
    </div>
    """
  end

  defp nav_item_class(active?) do
    [
      "mx-2 flex items-center gap-2 rounded-lg px-2 py-1.5 text-xs transition-colors",
      if(active?,
        do: "bg-primary-subtle font-medium text-primary",
        else: "text-text-muted hover:bg-surface-raised hover:text-text"
      )
    ]
  end

  defp instance_active?(current_path, instance_id),
    do: String.starts_with?(current_path, "/applications/#{instance_id}")

  defp applications_active?(current_path),
    do: current_path in ["/", "/applications"]

  defp breadcrumbs(current_path, instances) do
    instance = Enum.find(instances, &instance_active?(current_path, &1.id))

    cond do
      String.starts_with?(current_path, "/applications/new") ->
        [
          %{label: "Applications", href: "/applications"},
          %{label: "New Instance", href: nil}
        ]

      instance && instance_settings_active?(current_path, instance) ->
        [
          %{label: "Applications", href: "/applications"},
          %{label: instance.name, href: "/applications/#{instance.id}"},
          %{
            label:
              if(String.ends_with?(current_path, "/settings"),
                do: "General settings",
                else: "Application settings"
              ),
            href: nil
          }
        ]

      instance ->
        [%{label: "Applications", href: "/applications"}, %{label: instance.name, href: nil}]

      current_path == "/connections" ->
        [%{label: "Connections", href: nil}]

      current_path == "/settings" ->
        [%{label: "Settings", href: nil}]

      current_path == "/operations" ->
        [%{label: "Operations", href: nil}]

      String.starts_with?(current_path, "/users/settings") ->
        [%{label: "Account settings", href: nil}]

      true ->
        [%{label: "Applications", href: nil}]
    end
  end

  defp instance_settings_active?(current_path, instance) do
    String.ends_with?(current_path, "/settings") or
      (instance.settings_path && String.ends_with?(current_path, "/#{instance.settings_path}"))
  end

  defp agent_context(current_path, instances) do
    case Enum.find(instances, &instance_active?(current_path, &1.id)) do
      nil ->
        platform_agent_context(current_path)

      instance ->
        %{
          level: "Application Instance",
          title: instance.name,
          area: instance_area(current_path, instance),
          icon: instance.icon,
          instance_id: instance.id
        }
    end
  end

  defp platform_agent_context(current_path) do
    {title, area, icon} =
      cond do
        String.starts_with?(current_path, "/applications/new") ->
          {"New Application Instance", "Application setup", "hero-plus"}

        current_path == "/connections" ->
          {"Connections", "External system connections", "hero-link"}

        current_path == "/settings" ->
          {"Platform settings", "Installation configuration", "hero-cog-6-tooth"}

        current_path == "/operations" ->
          {"Operations", "Installation health and execution activity", "hero-command-line"}

        String.starts_with?(current_path, "/users/settings") ->
          {"Account settings", "Administrator account", "hero-user-circle"}

        true ->
          {"Applications", "Platform overview", "hero-squares-2x2"}
      end

    %{level: "Platform", title: title, area: area, icon: icon, instance_id: nil}
  end

  defp instance_area(current_path, instance) do
    suffix = String.replace_prefix(current_path, "/applications/#{instance.id}", "")

    case suffix do
      "" -> "Application overview"
      "/" -> "Application overview"
      "/settings" -> "General settings"
      path -> path |> String.trim("/") |> String.replace(~r/[-_]/, " ") |> String.capitalize()
    end
  end
end
