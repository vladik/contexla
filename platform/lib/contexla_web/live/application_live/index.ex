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
      <main class="mx-auto max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
        <header class="border-b border-base-300 pb-8">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-primary">Contexla</p>
          <h1 class="mt-2 text-3xl font-semibold tracking-tight">Applications</h1>
          <p class="mt-3 max-w-2xl text-base-content/65">
            Installed packages contribute their own workflows and interfaces.
          </p>
        </header>

        <section class="mt-8 grid gap-5 md:grid-cols-2">
          <article :for={application <- @applications} class="rounded-2xl border border-base-300 p-6">
            <h2 class="text-xl font-semibold">{application.name}</h2>
            <p class="mt-2 text-sm text-base-content/60">{application.description}</p>
            <a
              :for={surface <- Enum.filter(application.surfaces, &(&1.role == :new))}
              href={"/applications/new/#{URI.encode_www_form(application.id)}/#{surface.path}"}
              class="mt-5 inline-flex rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-500"
            >Create instance</a>
          </article>
          <div
            :if={@applications == []}
            class="rounded-2xl border border-dashed border-base-300 p-8 text-base-content/55"
          >
            No Application packages are installed. The platform is running independently.
          </div>
        </section>

        <section class="mt-10">
          <h2 class="text-xl font-semibold">Application instances</h2>
          <div class="mt-4 space-y-3">
            <a
              :for={instance <- @instances}
              href={"/applications/#{instance.id}/overview"}
              class="block rounded-xl border border-base-300 p-5 transition hover:border-indigo-500"
            >
              <span class="font-semibold">{instance.name}</span>
              <span class="ml-2 text-sm text-base-content/50">{instance.application_id}</span>
            </a>
            <p :if={@instances == []} class="text-sm text-base-content/55">No instances yet.</p>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end
end
