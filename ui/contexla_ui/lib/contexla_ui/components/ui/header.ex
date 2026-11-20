defmodule ContexlaUI.Components.UI.Header do
  @moduledoc "Provides the compact operational page header component."
  use Phoenix.Component
  import ContexlaUI.Components.UI.Icon

  attr(:id, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header
      id={@id}
      class={[
        "flex flex-shrink-0 items-center justify-between gap-3 border-b border-border bg-surface px-4 py-4 sm:px-6",
        @class
      ]}
    >
      <div class="flex min-w-0 items-center gap-3">
        <span class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary-subtle text-primary">
          <.icon name={@icon} class="size-5" />
        </span>
        <div class="min-w-0">
          <h1 class="truncate text-base font-semibold text-text">{render_slot(@inner_block)}</h1>
          <p :if={@subtitle != []} class="truncate text-xs text-text-muted">
            {render_slot(@subtitle)}
          </p>
        </div>
      </div>
      <div :if={@actions != []} class="flex shrink-0 items-center gap-2">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end
end
