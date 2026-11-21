defmodule ContexlaUI.Components.ApplicationFrame do
  @moduledoc """
  Standard frame for every configured Application Instance surface.

  Applications own navigation labels, routes, actions, and domain content. This
  component owns their placement inside the shared Contexla surface contract.
  """

  use Phoenix.Component

  import ContexlaUI.Components
  import ContexlaUI.Components.UI.Header

  attr(:id, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:flash, :map, default: nil)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:navigation)
  slot(:inner_block, required: true)

  def application_frame(assigns) do
    ~H"""
    <.surface flash={@flash} class={@class}>
      <:header>
        <.header id={@id} icon={@icon}>
          {@title}
          <:subtitle :if={@subtitle}>{@subtitle}</:subtitle>
          <:actions :if={@actions != []}>{render_slot(@actions)}</:actions>
        </.header>
      </:header>
      <:navigation :if={@navigation != []}>{render_slot(@navigation)}</:navigation>
      {render_slot(@inner_block)}
    </.surface>
    """
  end
end
