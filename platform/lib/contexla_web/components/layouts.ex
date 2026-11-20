defmodule ContexlaWeb.Layouts do
  @moduledoc "Platform-owned public and authenticated layouts."
  use ContexlaWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    <ContexlaUI.Components.UI.Toast.toast flash={@flash} id="platform-toast-group" />
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
            data-tooltip="New instance"
            data-tooltip-position="side"
            aria-current={if String.starts_with?(@current_path, "/applications/new"), do: "page"}
            class={nav_item_class(String.starts_with?(@current_path, "/applications/new"))}
          >
            <.icon name="hero-plus" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">New instance</span>
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
            href="/applications"
            data-sidebar-row
            data-tooltip="Apps"
            data-tooltip-position="side"
            aria-current={if applications_active?(@current_path), do: "page"}
            class={nav_item_class(applications_active?(@current_path))}
          >
            <.icon name="hero-squares-2x2" class="size-4 shrink-0" />
            <span data-sidebar-expanded class="min-w-0 flex-1 truncate">Apps</span>
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
        </header>

        <div class="flex-1 overflow-y-auto">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
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
    <ContexlaUI.Components.UI.Toast.toast flash={@flash} id={@id} />
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
        [%{label: "Apps", href: "/applications"}, %{label: "New instance", href: nil}]

      instance && instance_settings_active?(current_path, instance) ->
        [
          %{label: "Apps", href: "/applications"},
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
        [%{label: "Apps", href: "/applications"}, %{label: instance.name, href: nil}]

      current_path == "/settings" ->
        [%{label: "Settings", href: nil}]

      String.starts_with?(current_path, "/users/settings") ->
        [%{label: "Account settings", href: nil}]

      true ->
        [%{label: "Apps", href: nil}]
    end
  end

  defp instance_settings_active?(current_path, instance) do
    String.ends_with?(current_path, "/settings") or
      (instance.settings_path && String.ends_with?(current_path, "/#{instance.settings_path}"))
  end
end
