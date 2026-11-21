defmodule ContexlaUI.Components do
  @moduledoc "Domain-neutral surface composition helpers shared by Applications."
  use Phoenix.Component

  attr(:class, :any, default: nil)
  attr(:flash, :map, default: nil)
  slot(:header)
  slot(:navigation)
  slot(:inner_block, required: true)

  def surface(assigns) do
    ~H"""
    <div class={["application-surface flex h-full min-h-0 flex-col overflow-hidden bg-bg", @class]}>
      {render_slot(@header)}
      <div
        :if={@navigation != []}
        class="shrink-0 border-b border-border bg-surface px-4 py-2 sm:px-6"
      >
        {render_slot(@navigation)}
      </div>
      <div class="flex-1 overflow-y-auto p-4 sm:p-6">
        {render_slot(@inner_block)}
      </div>
    </div>
    <ContexlaUI.Components.UI.Toast.toast :if={@flash} flash={@flash} />
    """
  end

  attr(:title, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:icon, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def panel(assigns) do
    ~H"""
    <section class={["rounded-2xl border border-border bg-surface p-5 sm:p-6", @class]}>
      <div
        :if={@title || @description || @actions != []}
        class="mb-5 flex items-start justify-between gap-4"
      >
        <div class="flex min-w-0 items-start gap-3">
          <span
            :if={@icon}
            class="grid size-9 shrink-0 place-items-center rounded-lg bg-primary-subtle text-primary"
          >
            <ContexlaUI.Components.UI.Icon.icon name={@icon} class="size-4" />
          </span>
          <div>
            <h2 :if={@title} class="text-sm font-semibold text-text">{@title}</h2>
            <p :if={@description} class="mt-0.5 text-xs leading-5 text-text-muted">{@description}</p>
          </div>
        </div>
        <div :if={@actions != []} class="flex shrink-0 items-center gap-2">
          {render_slot(@actions)}
        </div>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:hint, :string, default: nil)
  attr(:class, :any, default: nil)

  def stat(assigns) do
    ~H"""
    <div class={["rounded-xl border border-border bg-surface p-5", @class]}>
      <strong class="block text-2xl font-semibold text-text">{@value}</strong>
      <span class="mt-1 block text-xs font-medium uppercase tracking-wide text-text-muted">{@label}</span>
      <span :if={@hint} class="mt-2 block text-xs text-text-muted">{@hint}</span>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:icon, :string, default: "hero-inbox")
  slot(:actions)

  def empty_state(assigns) do
    ~H"""
    <div class="flex min-h-72 flex-col items-center justify-center rounded-xl border border-border bg-surface px-6 py-12 text-center shadow-sm">
      <span class="grid size-12 place-items-center rounded-2xl bg-primary-subtle text-primary"><ContexlaUI.Components.UI.Icon.icon
        name={@icon}
        class="size-6"
      /></span>
      <h3 class="mt-5 font-semibold text-text">{@title}</h3>
      <p :if={@description} class="mx-auto mt-2 max-w-xl text-sm leading-6 text-text-muted">
        {@description}
      </p>
      <div :if={@actions != []} class="mt-5">{render_slot(@actions)}</div>
    </div>
    """
  end
end
