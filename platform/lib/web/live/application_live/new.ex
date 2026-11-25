defmodule Contexla.Platform.Web.ApplicationLive.New do
  use Contexla.Platform.Web, :live_view

  alias Contexla.Platform.Applications

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "New Application Instance")
     |> assign(
       :applications,
       Applications.list_installed_applications(socket.assigns.current_scope)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.surface>
        <:header>
          <.header id="new-instance-page-header" icon="hero-plus">
            New Application Instance
            <:subtitle>Choose an installed Application to configure.</:subtitle>
            <:actions>
              <UIButton.button href="/applications" size="sm">Back</UIButton.button>
            </:actions>
          </.header>
        </:header>

        <section class="overflow-hidden rounded-2xl border border-border bg-surface">
          <div class="border-b border-border px-4 py-3 sm:px-5">
            <h2 class="text-sm font-semibold text-text">Choose an Application</h2>
            <p class="mt-0.5 text-xs text-text-muted">
              The selected Application provides the remaining setup steps.
            </p>
          </div>

          <div class="divide-y divide-border">
            <a
              :for={application <- @applications}
              href={new_surface_path(application)}
              class="group flex items-center justify-between gap-4 px-4 py-3 transition hover:bg-surface-raised sm:px-5"
            >
              <div class="flex min-w-0 items-center gap-3">
                <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-primary-subtle text-primary">
                  <.icon name={application.icon} class="size-4" />
                </span>
                <div class="min-w-0">
                  <h3 class="truncate text-sm font-semibold text-text">{application.name}</h3>
                  <p class="mt-0.5 text-xs text-text-muted">{application.description}</p>
                </div>
              </div>
              <span class="flex shrink-0 items-center gap-1 text-xs font-semibold text-primary">
                Configure <.icon name="hero-chevron-right" class="size-4" />
              </span>
            </a>
          </div>
        </section>
      </.surface>
    </Layouts.app>
    """
  end

  defp new_surface_path(application) do
    surface = Enum.find(application.surfaces, &(&1.role == :new))
    "/applications/new/#{URI.encode_www_form(application.id)}/#{surface.path}"
  end
end
