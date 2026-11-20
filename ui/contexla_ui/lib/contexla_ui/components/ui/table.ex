defmodule ContexlaUI.Components.UI.Table do
  @moduledoc "Provides a generic styled table."
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil)
  attr(:row_click, :any, default: nil)
  attr(:row_item, :any, default: &Function.identity/1)
  attr(:class, :any, default: nil)

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action)

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={["overflow-x-auto rounded-xl border border-border", @class]}>
      <table class="min-w-full divide-y divide-border">
        <thead class="bg-surface-raised">
          <tr>
            <th
              :for={col <- @col}
              scope="col"
              class="px-3 py-2 text-start text-xs font-medium uppercase tracking-wider text-text-muted"
            >
              {col[:label]}
            </th>
            <th
              :if={@action != []}
              scope="col"
              class="px-3 py-2 text-start text-xs font-medium uppercase tracking-wider text-text-muted"
            >
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class="divide-y divide-border bg-surface"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="hover:bg-surface-raised">
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["px-3 py-2 text-sm text-text", @row_click && "hover:cursor-pointer"]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="w-0 px-3 py-2 font-semibold">
              <div class="flex gap-4">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
