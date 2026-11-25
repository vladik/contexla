defmodule Contexla.Platform.Web.PlatformSettingsLive do
  use Contexla.Platform.Web, :live_view

  alias Contexla.Platform.Applications

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(
       :application_count,
       length(Applications.list_installed_applications(socket.assigns.current_scope))
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.surface>
        <:header>
          <.header id="platform-settings-header" icon="hero-cog-6-tooth">
            Settings
            <:subtitle>Installation-level configuration and administration</:subtitle>
          </.header>
        </:header>

        <div class="grid content-start gap-4 lg:grid-cols-2">
          <.panel
            title="Deployment"
            description="This installation represents one organization."
            icon="hero-server-stack"
          >
            <dl class="space-y-3 text-sm">
              <div class="flex items-center justify-between gap-4">
                <dt class="text-text-muted">Tenancy model</dt>
                <dd class="font-medium text-text">Single organization</dd>
              </div>
              <div class="flex items-center justify-between gap-4">
                <dt class="text-text-muted">Installed Applications</dt>
                <dd class="font-medium text-text">{@application_count}</dd>
              </div>
            </dl>
          </.panel>

          <.panel
            title="Administrator account"
            description="Manage the administrator identity and credentials."
            icon="hero-user-circle"
          >
            <p class="text-sm text-text-muted">{@current_scope.user.email}</p>
            <UIButton.button href="/users/settings" size="sm" class="mt-4">
              Account settings
            </UIButton.button>
          </.panel>
        </div>
      </.surface>
    </Layouts.app>
    """
  end
end
