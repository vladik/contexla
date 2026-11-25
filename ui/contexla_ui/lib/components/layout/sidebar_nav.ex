defmodule Contexla.Ui.ContexlaUi.Components.Layout.SidebarNav do
  @moduledoc "Shared navigation row for collapsible platform panels."
  use Phoenix.Component
  import Contexla.Ui.ContexlaUi.Components.UI.Icon
  import Contexla.Ui.ContexlaUi.Components.UI.Tooltip

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:navigate, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:active, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  def nav_item(assigns) do
    ~H"""
    <.tooltip text={@label} position="side" class="block">
      <span
        :if={@disabled}
        class="mx-2 flex cursor-default items-center gap-2 rounded-lg px-2 py-1.5 text-xs text-text-muted/55"
        aria-disabled="true"
        data-sidebar-row
      >
        <.icon name={@icon} class="size-4 shrink-0" />
        <span data-sidebar-expanded>{@label}</span>
      </span>
      <.link
        :if={!@disabled}
        navigate={@navigate}
        href={@href}
        data-sidebar-row
        class={[
          "mx-2 flex items-center gap-2 rounded-lg px-2 py-1.5 text-xs transition-colors",
          if(@active,
            do: "bg-primary-subtle font-medium text-primary",
            else: "text-text-muted hover:bg-surface-raised hover:text-text"
          )
        ]}
      >
        <.icon name={@icon} class="size-4 shrink-0" />
        <span data-sidebar-expanded>{@label}</span>
      </.link>
    </.tooltip>
    """
  end
end
