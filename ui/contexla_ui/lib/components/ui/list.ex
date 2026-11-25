defmodule Contexla.Ui.ContexlaUi.Components.UI.List do
  @moduledoc "Provides the shared data list component."
  use Phoenix.Component

  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <ul class="divide-y divide-border">
      <li :for={item <- @item} class="flex items-start gap-3 py-3">
        <div class="flex-1">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end
end
