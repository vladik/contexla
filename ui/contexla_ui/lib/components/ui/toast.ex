defmodule Contexla.Ui.ContexlaUi.Components.UI.Toast do
  @moduledoc "Displays auto-dismissing flash notifications."
  use Phoenix.Component
  alias Contexla.Ui.ContexlaUi.Components.UI.Icon

  attr(:flash, :map, default: %{})
  attr(:id, :string, default: "toast-group")

  def toast(assigns) do
    ~H"""
    <div
      id={@id}
      aria-live="polite"
      class="fixed bottom-4 z-[100] flex w-[calc(100%_-_2rem)] max-w-[30rem] flex-col gap-2"
      style="inset-inline-end: 1rem;"
    >
      <.toast_item :if={msg = Phoenix.Flash.get(@flash, :info)} kind={:info} msg={msg} />
      <.toast_item :if={msg = Phoenix.Flash.get(@flash, :success)} kind={:success} msg={msg} />
      <.toast_item :if={msg = Phoenix.Flash.get(@flash, :error)} kind={:error} msg={msg} />
    </div>
    """
  end

  attr(:kind, :atom, required: true, values: [:info, :error, :success])
  attr(:msg, :string, required: true)

  defp toast_item(assigns) do
    assigns = assign(assigns, :id, "toast-#{System.unique_integer([:positive])}")

    ~H"""
    <div
      id={@id}
      role="alert"
      data-toast
      phx-hook="ToastDismiss"
      class={[
        "toast-animate-in flex w-full items-start gap-3 rounded-xl border p-4 shadow-lg transition-all duration-300",
        @kind == :info &&
          "border-blue-200 bg-blue-50 text-blue-800 dark:border-blue-800 dark:bg-blue-950 dark:text-blue-300",
        @kind == :error &&
          "border-red-200 bg-red-50 text-red-800 dark:border-red-800 dark:bg-red-950 dark:text-red-300",
        @kind == :success &&
          "border-emerald-200 bg-emerald-50 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-300"
      ]}
    >
      <Icon.icon :if={@kind == :info} name="hero-information-circle" class="mt-0.5 size-5 shrink-0" />
      <Icon.icon :if={@kind == :error} name="hero-exclamation-circle" class="mt-0.5 size-5 shrink-0" />
      <Icon.icon :if={@kind == :success} name="hero-check-circle" class="mt-0.5 size-5 shrink-0" />
      <p class="flex-1 text-sm font-medium">{@msg}</p>
      <button
        type="button"
        data-toast-dismiss
        class="shrink-0 opacity-50 transition-opacity hover:opacity-80"
        aria-label="Close"
      >
        <Icon.icon name="hero-x-mark" class="size-4" />
      </button>
    </div>
    """
  end
end
