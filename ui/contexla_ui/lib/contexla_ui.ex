defmodule ContexlaUI do
  @moduledoc """
  Route-independent UI primitives shared by the Contexla platform and trusted
  Application packages.

  This package deliberately contains no platform routes, repositories,
  authentication, or Application domain logic.
  """

  def live_view do
    quote do
      use Phoenix.LiveView
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      unquote(html_helpers())
    end
  end

  defmacro __using__(which) when which in [:live_view, :html] do
    apply(__MODULE__, which, [])
  end

  defp html_helpers do
    quote do
      import ContexlaUI.Components
      import ContexlaUI.Components.ApplicationFrame
      import ContexlaUI.Components.Layout.Patterns
      import ContexlaUI.Components.UI.Button
      import ContexlaUI.Components.UI.Header
      import ContexlaUI.Components.UI.Icon
      import ContexlaUI.Components.UI.IconPicker
      import ContexlaUI.Components.UI.Input
      import ContexlaUI.Components.UI.List
      import ContexlaUI.Components.UI.Modal
      import ContexlaUI.Components.UI.Table
      import ContexlaUI.Components.UI.Tabs
      import ContexlaUI.Components.UI.Tooltip
      import ContexlaUI.Components.UI.Avatar
      import ContexlaUI.Components.UI.Toast
      import ContexlaUI.Components.Layout.SidebarNav
    end
  end
end
