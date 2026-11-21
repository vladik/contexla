defmodule ContexlaUI.Components.Layout.Patterns do
  @moduledoc "Reusable, route-independent Application surface patterns."

  use Phoenix.Component

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)
  slot(:actions)

  def form_layout(assigns) do
    ~H"""
    <div class={[@class, "space-y-5"]}>
      {render_slot(@inner_block)}
      <div
        :if={@actions != []}
        class="flex items-center justify-end gap-2 border-t border-border pt-5"
      >
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def form_section(assigns) do
    ~H"""
    <section class={[@class, "rounded-xl border border-border bg-surface-raised/45"]}>
      <div class="border-b border-border px-4 py-3 sm:px-5">
        <h3 class="text-sm font-semibold text-text">{@title}</h3>
        <p :if={@description} class="mt-0.5 text-xs leading-5 text-text-muted">
          {@description}
        </p>
      </div>
      <div class="space-y-4 p-4 sm:p-5">{render_slot(@inner_block)}</div>
    </section>
    """
  end

  attr(:class, :any, default: nil)
  attr(:list_label, :string, default: "Items")
  attr(:detail_label, :string, default: "Selected item")
  slot(:list, required: true)
  slot(:detail, required: true)

  def list_detail(assigns) do
    ~H"""
    <div class={[
      @class,
      "grid min-h-0 overflow-hidden rounded-2xl border border-border bg-surface lg:grid-cols-[minmax(16rem,0.8fr)_minmax(0,1.4fr)]"
    ]}>
      <section
        class="min-w-0 border-b border-border lg:border-b-0 lg:border-r"
        aria-label={@list_label}
      >
        {render_slot(@list)}
      </section>
      <section class="min-w-0 bg-surface" aria-label={@detail_label}>
        {render_slot(@detail)}
      </section>
    </div>
    """
  end
end
