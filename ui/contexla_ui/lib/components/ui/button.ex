defmodule Contexla.Ui.ContexlaUi.Components.UI.Button do
  @moduledoc "Provides the shared button component with navigation support."
  use Phoenix.Component

  attr(:rest, :global, include: ~w(href navigate patch method download name value type disabled))
  attr(:class, :any, default: nil)

  attr(:variant, :string,
    default: "outline",
    values: ~w(primary soft ghost outline danger danger-ghost)
  )

  attr(:size, :string, default: "md", values: ~w(sm md))
  slot(:inner_block, required: true)

  def button(%{rest: rest} = assigns) do
    variant_class =
      case assigns.variant do
        "primary" -> "btn-primary"
        "soft" -> "btn-soft"
        "ghost" -> "btn-ghost"
        "danger" -> "btn-danger"
        "danger-ghost" -> "btn-danger-ghost"
        _ -> "btn-outline"
      end

    size_class = if assigns.size == "sm", do: "btn-sm"
    assigns = assign(assigns, :class, ["btn", variant_class, size_class, assigns.class])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>{render_slot(@inner_block)}</.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>{render_slot(@inner_block)}</button>
      """
    end
  end
end
