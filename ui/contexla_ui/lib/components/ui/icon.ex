defmodule Contexla.Ui.ContexlaUi.Components.UI.Icon do
  @moduledoc "Renders Heroicons bundled by the host asset pipeline."
  use Phoenix.Component

  attr(:name, :string, required: true)
  attr(:class, :any, default: "size-4")

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end
end
