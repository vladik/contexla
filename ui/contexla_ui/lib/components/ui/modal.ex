defmodule Contexla.Ui.ContexlaUi.Components.UI.Modal do
  @moduledoc "Modal dialog using Phoenix.LiveView.JS commands."
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Contexla.Ui.ContexlaUi.Components.UI.Icon

  attr(:id, :string, required: true)
  attr(:size, :string, default: "md", values: ~w(sm md lg))
  slot(:inner_block, required: true)
  slot(:header)
  slot(:footer)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 hidden"
      phx-window-keydown={hide_modal(@id)}
      phx-key="escape"
    >
      <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" phx-click={hide_modal(@id)} />
      <div class="fixed inset-0 flex items-center justify-center p-4">
        <.focus_wrap
          id={"#{@id}-dialog"}
          role="dialog"
          aria-modal="true"
          aria-labelledby={if @header != [], do: "#{@id}-title"}
          tabindex="-1"
          class={[
            "flex max-h-[calc(100dvh-2rem)] w-full flex-col overflow-hidden rounded-xl border border-border bg-surface shadow-2xl",
            modal_width(@size)
          ]}
        >
          <div
            :if={@header != []}
            class="flex items-center justify-between border-b border-border px-6 py-4"
          >
            <div id={"#{@id}-title"} class="text-base font-semibold text-text">
              {render_slot(hd(@header))}
            </div>
            <button
              type="button"
              phx-click={hide_modal(@id)}
              class="flex size-7 items-center justify-center rounded-md text-text-muted transition-colors hover:bg-surface-raised hover:text-text"
              aria-label="Close dialog"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>
          </div>
          <div class="overflow-y-auto px-6 py-4 text-sm text-text-muted">
            {render_slot(@inner_block)}
          </div>
          <div
            :if={@footer != []}
            class="flex flex-col-reverse gap-2 rounded-b-xl border-t border-border bg-surface-raised px-6 py-4 sm:flex-row sm:items-center sm:justify-end sm:gap-3"
          >
            {render_slot(@footer)}
          </div>
        </.focus_wrap>
      </div>
    </div>
    """
  end

  def show_modal(id), do: JS.show(%JS{}, to: "##{id}") |> JS.focus_first(to: "##{id}-dialog")
  def hide_modal(id), do: JS.hide(%JS{}, to: "##{id}") |> JS.pop_focus()

  defp modal_width("sm"), do: "max-w-sm"
  defp modal_width("md"), do: "max-w-md"
  defp modal_width("lg"), do: "max-w-lg"
end
