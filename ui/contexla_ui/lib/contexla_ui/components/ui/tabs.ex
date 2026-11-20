defmodule ContexlaUI.Components.UI.Tabs do
  @moduledoc "Responsive tab navigation with icons and optional badges."
  use Phoenix.Component
  import ContexlaUI.Components.UI.Icon

  attr(:id, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:label, :string, default: "Section navigation")

  slot :tab, required: true do
    attr(:label, :string, required: true)
    attr(:icon, :string, required: true)
    attr(:selected, :boolean)
    attr(:patch, :string)
    attr(:navigate, :string)
    attr(:badge, :string)
  end

  def tabs(assigns) do
    ~H"""
    <nav
      id={@id}
      aria-label={@label}
      class={["flex items-center gap-0.5 overflow-x-auto", @class]}
    >
      <%= for tab <- @tab do %>
        <% selected = Map.get(tab, :selected, false) %>
        <% badge = Map.get(tab, :badge) %>
        <.link :if={Map.get(tab, :patch)} patch={tab.patch} class={tab_class(selected)}>
          <.icon name={tab.icon} class="size-3.5 shrink-0" /> {tab.label}
          <span :if={badge} class="rounded-full bg-surface-raised px-1.5 py-0.5 text-[10px]">{badge}</span>
        </.link>
        <.link
          :if={!Map.get(tab, :patch) && Map.get(tab, :navigate)}
          navigate={tab.navigate}
          class={tab_class(selected)}
        >
          <.icon name={tab.icon} class="size-3.5 shrink-0" /> {tab.label}
          <span :if={badge} class="rounded-full bg-surface-raised px-1.5 py-0.5 text-[10px]">{badge}</span>
        </.link>
      <% end %>
    </nav>
    """
  end

  defp tab_class(selected) do
    [
      "flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-xs font-medium transition-colors whitespace-nowrap",
      if(selected,
        do: "bg-primary-subtle text-primary",
        else: "text-text-muted hover:bg-surface-raised hover:text-text"
      )
    ]
  end
end
