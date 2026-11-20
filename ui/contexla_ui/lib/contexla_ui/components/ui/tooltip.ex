defmodule ContexlaUI.Components.UI.Tooltip do
  @moduledoc "A tooltip trigger rendered by the host's document-level overlay."
  use Phoenix.Component

  attr(:text, :string, required: true)
  attr(:position, :string, default: "top", values: ~w(top bottom left right side))
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <span class={@class} data-tooltip={@text} data-tooltip-position={@position}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
