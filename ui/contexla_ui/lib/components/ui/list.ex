defmodule Contexla.Ui.ContexlaUi.Components.UI.List do
  @moduledoc "Provides a sortable record list component."
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, required: true)
  attr(:editing_id, :any, default: nil)
  attr(:sortable, :boolean, default: false)
  attr(:on_move, :string, default: nil)

  slot(:row, required: true)
  slot(:action)

  def list(assigns) do
    ~H"""
    <ul id={@id} class="divide-y divide-border">
      <li
        :for={{item, index} <- Enum.with_index(@rows)}
        id={"#{@id}-row-#{@row_id.(item)}"}
        class={[
          "py-3",
          index == 0 && "pt-0",
          index == length(@rows) - 1 && "pb-0"
        ]}
      >
        <div class={[
          "flex items-center gap-3",
          not is_nil(@editing_id) && @editing_id == @row_id.(item) && "opacity-50"
        ]}>
          <div class="min-w-0 flex-1">
            {render_slot(@row, item)}
          </div>
          <div class="flex shrink-0 items-center gap-1">
            <button
              :if={@sortable}
              type="button"
              phx-click={@on_move}
              phx-value-id={@row_id.(item)}
              phx-value-direction="up"
              disabled={index == 0}
              class="btn btn-ghost btn-sm disabled:opacity-30"
              aria-label="Move up"
            >
              <Contexla.Ui.ContexlaUi.Components.UI.Icon.icon name="hero-arrow-up" class="size-4" />
            </button>
            <button
              :if={@sortable}
              type="button"
              phx-click={@on_move}
              phx-value-id={@row_id.(item)}
              phx-value-direction="down"
              disabled={index == length(@rows) - 1}
              class="btn btn-ghost btn-sm disabled:opacity-30"
              aria-label="Move down"
            >
              <Contexla.Ui.ContexlaUi.Components.UI.Icon.icon name="hero-arrow-up" class="size-4 rotate-180" />
            </button>
            {render_slot(@action, item)}
          </div>
        </div>
      </li>
    </ul>
    """
  end
end
