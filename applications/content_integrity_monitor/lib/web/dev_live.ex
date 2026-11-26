defmodule Contexla.Applications.ContentIntegrityMonitor.Web.DevLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource
  alias Contexla.Applications.Sdk.{Instance, Runtime}

  @simulator_port 4205
  @modes [:healthy, :overdue, :pending, :unavailable]

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)
    {:ok, socket |> assign(:instance, instance) |> load_simulator_state()}
  end

  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) do
    ExternalHttpSource.State.set_mode(String.to_existing_atom(mode))
    {:noreply, load_simulator_state(socket)}
  end

  def handle_event("create_demo_monitor", _params, socket) do
    instance = socket.assigns.instance

    case Runtime.invoke_operation(instance.actor_id, instance.id, "integrity.demo_setup", %{},
           approved: true
         ) do
      {:ok, _result, _invocation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Monitor ready — click Run to check integrity.")
         |> redirect(to: "/applications/#{instance.id}")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not create the monitor.")}
    end
  end

  defp load_simulator_state(socket) do
    running = running?()

    assign(socket,
      simulator_running: running,
      simulator_mode: if(running, do: ExternalHttpSource.State.mode(), else: nil),
      simulator_port: @simulator_port
    )
  end

  defp running? do
    case Process.whereis(ExternalHttpSource.State) do
      nil -> false
      _pid -> true
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :modes, @modes)

    ~H"""
    <.application_frame
      id="integrity-dev"
      icon="hero-shield-check"
      title={@instance.name}
      subtitle="Developer"
      flash={assigns[:flash]}
    >
      <:navigation>
        <.tabs id="settings-navigation">
          <:tab
            label="General"
            icon="hero-identification"
            navigate={"/applications/#{@instance.id}/settings"}
          />
          <:tab
            label="Application"
            icon="hero-adjustments-horizontal"
            navigate={"/applications/#{@instance.id}/configuration"}
          />
          <:tab
            label="Developer"
            icon="hero-code-bracket"
            navigate={"/applications/#{@instance.id}/dev"}
            selected
          />
        </.tabs>
      </:navigation>

      <div class="mt-6 space-y-4">
        <.panel title="Simulator" description="Synthetic content source for local development and walkthroughs.">
          <div class="space-y-5">
            <div class="flex items-center gap-3">
              <span class={[
                "inline-flex size-2.5 rounded-full",
                if(@simulator_running, do: "bg-emerald-500", else: "bg-red-400")
              ]} />
              <span class="text-sm text-text">
                <%= if @simulator_running do %>
                  Running on port {@simulator_port}
                <% else %>
                  Not running
                <% end %>
              </span>
            </div>

            <div :if={@simulator_running} class="space-y-2">
              <p class="text-xs font-medium uppercase tracking-wide text-text-muted">Current mode</p>
              <div class="flex flex-wrap gap-2">
                <button
                  :for={mode <- @modes}
                  phx-click="set_mode"
                  phx-value-mode={mode}
                  class={[
                    "rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors",
                    if(mode == @simulator_mode,
                      do: "border-primary bg-primary-subtle text-primary",
                      else: "border-border bg-surface text-text-muted hover:bg-surface-raised hover:text-text"
                    )
                  ]}
                >
                  {mode_label(mode)}
                </button>
              </div>
              <p class="text-xs text-text-muted">{mode_description(@simulator_mode)}</p>
            </div>
          </div>
        </.panel>

        <.panel title="Quick start" description="Create a pre-configured collection monitor pointed at the simulator.">
          <div class="flex items-center justify-between gap-4">
            <p class="text-sm text-text-muted">
              Creates a <strong class="font-medium text-text">Program content delivery</strong>
              collection monitor tracking three programs (PN100, PN101, PN102) across a scope
              source, authority API, delivery API, public page, and search.
            </p>
            <.button
              id="create-demo-monitor"
              phx-click="create_demo_monitor"
              variant="soft"
              class="shrink-0"
            >
              Create monitor
            </.button>
          </div>
        </.panel>

        <.panel title="Sources" description="Simulator endpoints. Programs: PN100, PN101, PN102.">
          <div class="divide-y divide-border">
            <div class="flex items-center gap-3 py-2.5 first:pt-0 last:pb-0">
              <span class="w-32 shrink-0 text-xs font-medium text-text-muted">Scope</span>
              <code class="text-xs text-text">http://localhost:{@simulator_port}/scope/programs</code>
            </div>
            <div class="flex items-center gap-3 py-2.5">
              <span class="w-32 shrink-0 text-xs font-medium text-text-muted">Authority API</span>
              <code class="text-xs text-text">http://localhost:{@simulator_port}/authority/programs/:id</code>
            </div>
            <div class="flex items-center gap-3 py-2.5">
              <span class="w-32 shrink-0 text-xs font-medium text-text-muted">Delivery API</span>
              <code class="text-xs text-text">http://localhost:{@simulator_port}/delivery/programs/:id</code>
            </div>
            <div class="flex items-center gap-3 py-2.5">
              <span class="w-32 shrink-0 text-xs font-medium text-text-muted">Public page</span>
              <code class="text-xs text-text">http://localhost:{@simulator_port}/programs/:id</code>
            </div>
            <div class="flex items-center gap-3 py-2.5 last:pb-0">
              <span class="w-32 shrink-0 text-xs font-medium text-text-muted">Search</span>
              <code class="text-xs text-text">http://localhost:{@simulator_port}/search/programs/:id</code>
            </div>
          </div>
        </.panel>

        <.panel title="Starting the server" description="Run these commands once to start the platform with this Application in development.">
          <div class="space-y-3">
            <div class="flex items-start gap-3">
              <code class="rounded bg-surface-raised px-2 py-1 text-xs text-text">docker compose up -d postgres</code>
              <span class="text-sm text-text-muted">Start PostgreSQL</span>
            </div>
            <div class="flex items-start gap-3">
              <code class="rounded bg-surface-raised px-2 py-1 text-xs text-text">.\scripts\dev-integrity.ps1</code>
              <span class="text-sm text-text-muted">Start the platform with this Application source-linked. The simulator starts automatically.</span>
            </div>
          </div>
        </.panel>
      </div>
    </.application_frame>
    """
  end

  defp mode_label(:healthy), do: "Healthy"
  defp mode_label(:overdue), do: "Overdue"
  defp mode_label(:pending), do: "Pending"
  defp mode_label(:unavailable), do: "Unavailable"

  defp mode_description(:healthy),
    do: "All sources return consistent, up-to-date data. Everything checks out."

  defp mode_description(:overdue),
    do:
      "Sources return data with a timestamp 4 hours in the past. Delivery and downstream sources will appear overdue."

  defp mode_description(:pending),
    do:
      "Sources return a current timestamp. The website returns a mismatched credential — simulates a publish that has not yet propagated."

  defp mode_description(:unavailable),
    do: "The search endpoint returns 503. Simulates a Solr outage or failed reindex."

  defp mode_description(nil), do: ""
end
