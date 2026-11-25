defmodule Contexla.Ui.ContexlaUi.Components.UI.Avatar do
  @moduledoc "Displays an image or initial-letter avatar."
  use Phoenix.Component

  attr(:user, :map, default: nil)
  attr(:name, :string, default: nil)
  attr(:avatar_url, :string, default: nil)
  attr(:email, :string, default: nil)
  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:class, :string, default: "")

  def avatar(assigns) do
    user = assigns.user
    name = assigns.name || (user && Map.get(user, :name))
    email = assigns.email || (user && Map.get(user, :email))
    avatar_url = assigns.avatar_url || (user && Map.get(user, :avatar_url))
    display_name = name || email || "Unknown"

    assigns =
      assigns
      |> assign(:initial, display_name |> String.first() |> String.upcase())
      |> assign(:avatar_url, avatar_url)
      |> assign(:display_name, display_name)
      |> assign(:size_classes, size_classes(assigns.size))

    ~H"""
    <div class={[
      "flex flex-shrink-0 items-center justify-center rounded-full text-white font-semibold",
      @size_classes,
      !@avatar_url && "bg-primary",
      @class
    ]}>
      <img
        :if={@avatar_url}
        src={@avatar_url}
        alt={@display_name}
        class="size-full rounded-full object-cover"
      />
      <span :if={!@avatar_url}>{@initial}</span>
    </div>
    """
  end

  defp size_classes("xs"), do: "size-6 text-xs"
  defp size_classes("sm"), do: "size-8 text-sm"
  defp size_classes("md"), do: "size-10 text-sm"
  defp size_classes("lg"), do: "size-12 text-base"
  defp size_classes("xl"), do: "size-16 text-lg"
end
