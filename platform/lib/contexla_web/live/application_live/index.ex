defmodule ContexlaWeb.ApplicationLive.Index do
  use ContexlaWeb, :live_view

  alias Contexla.Applications

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:page_title, "Applications")
     |> assign(:applications, Applications.list_installed_applications(scope))
     |> assign(:instances, Applications.list_instances(scope))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.surface>
        <:header>
          <.header id="applications-page-header" icon="hero-squares-2x2">
            Applications
            <:subtitle>Installed Applications and their configured Instances</:subtitle>
            <:actions>
              <UIButton.button href="/applications/new" variant="primary" size="sm">
                <.icon name="hero-plus" class="size-4" /> New Instance
              </UIButton.button>
            </:actions>
          </.header>
        </:header>

        <div class="space-y-4">
          <section class="overflow-hidden rounded-2xl border border-border bg-surface">
            <div class="border-b border-border px-4 py-3 sm:px-5">
              <h2 class="text-sm font-semibold text-text">Installed Applications</h2>
              <p class="mt-0.5 text-xs text-text-muted">
                Applications available on this installation
              </p>
            </div>
            <div class="divide-y divide-border">
              <div
                :for={application <- @applications}
                class="flex items-center justify-between gap-4 px-4 py-3 sm:px-5"
              >
                <div class="flex min-w-0 items-center gap-3">
                  <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-primary-subtle text-primary">
                    <.icon name={application.icon} class="size-4" />
                  </span>
                  <div class="min-w-0">
                    <h3 class="truncate text-sm font-semibold text-text">{application.name}</h3>
                    <p class="mt-0.5 text-xs text-text-muted">
                      {application.description} · Version {application.version}
                    </p>
                  </div>
                </div>
                <UIButton.button
                  :for={surface <- Enum.filter(application.surfaces, &(&1.role == :new))}
                  href={"/applications/new/#{URI.encode_www_form(application.id)}/#{surface.path}"}
                  variant="primary"
                  size="sm"
                >Create Instance</UIButton.button>
              </div>
              <div :if={@applications == []} class="py-10 text-center text-sm text-text-muted">
                No Applications installed.
              </div>
            </div>
          </section>

          <section class="overflow-hidden rounded-2xl border border-border bg-surface">
            <div class="border-b border-border px-4 py-3 sm:px-5">
              <h2 class="text-sm font-semibold text-text">Application Instances</h2>
              <p class="mt-0.5 text-xs text-text-muted">
                Configured uses of the installed Applications
              </p>
            </div>
            <div class="divide-y divide-border">
              <a
                :for={instance <- @instances}
                href={"/applications/#{instance.id}"}
                class="flex items-center justify-between gap-4 px-4 py-3 transition hover:bg-surface-raised sm:px-5"
              >
                <span class="min-w-0">
                  <span class="block truncate text-sm font-semibold text-text">{instance.name}</span>
                  <span class="mt-0.5 block truncate text-xs text-text-muted">{instance.application_id}</span>
                </span>
                <.icon name="hero-chevron-right" class="size-4 shrink-0 text-text-muted" />
              </a>
              <div :if={@instances == []} class="py-10 text-center text-sm text-text-muted">
                No Application Instances yet.
              </div>
            </div>
          </section>
        </div>
      </.surface>
    </Layouts.app>
    """
  end
end
