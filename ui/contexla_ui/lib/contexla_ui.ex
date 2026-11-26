defmodule Contexla.Ui.ContexlaUi do
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
      import Contexla.Ui.ContexlaUi.Components
      import Contexla.Ui.ContexlaUi.Components.ApplicationFrame
      import Contexla.Ui.ContexlaUi.Components.Layout.Patterns
      import Contexla.Ui.ContexlaUi.Components.UI.Button
      import Contexla.Ui.ContexlaUi.Components.UI.Header
      import Contexla.Ui.ContexlaUi.Components.UI.Icon
      import Contexla.Ui.ContexlaUi.Components.UI.IconPicker
      import Contexla.Ui.ContexlaUi.Components.UI.Input
      import Contexla.Ui.ContexlaUi.Components.UI.List
      import Contexla.Ui.ContexlaUi.Components.UI.Modal
      import Contexla.Ui.ContexlaUi.Components.UI.Table
      import Contexla.Ui.ContexlaUi.Components.UI.Tabs
      import Contexla.Ui.ContexlaUi.Components.UI.Tooltip
      import Contexla.Ui.ContexlaUi.Components.UI.Avatar
      import Contexla.Ui.ContexlaUi.Components.UI.Toast
      import Contexla.Ui.ContexlaUi.Components.UI.TagInput
      import Contexla.Ui.ContexlaUi.Components.Layout.SidebarNav
    end
  end
end
