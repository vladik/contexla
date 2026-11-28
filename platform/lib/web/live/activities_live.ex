defmodule Contexla.Platform.Web.ActivitiesLive do
  use Contexla.Platform.Web, :live_view

  alias Contexla.Platform.ApplicationOperations
  alias Contexla.Platform.Packages.Registry

  @refresh_interval 15_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: schedule_refresh()

    {:ok,
     socket
     |> assign(:page_title, "Activity")
     |> assign(:operation_names, load_operation_names())
     |> load_invocations()}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, load_invocations(socket)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()
    {:noreply, load_invocations(socket)}
  end

  defp load_invocations(socket) do
    invocations =
      ApplicationOperations.list_recent_invocations(socket.assigns.current_scope, limit: 50)

    assign(socket, :invocations, invocations)
  end

  defp load_operation_names do
    Registry.applications()
    |> Enum.flat_map(fn definition ->
      Enum.map(definition.operations, fn op -> {op.id, op.name} end)
    end)
    |> Map.new()
  rescue
    _ -> %{}
  end

  defp schedule_refresh, do: Process.send_after(self(), :refresh, @refresh_interval)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.surface>
        <:header>
          <.header id="activities-header" icon="hero-queue-list">
            Activity
            <:subtitle>Recent Operation Invocations across your Application Instances</:subtitle>
            <:actions>
              <UIButton.button phx-click="refresh" size="sm">
                <.icon name="hero-arrow-path" class="size-4" /> Refresh
              </UIButton.button>
            </:actions>
          </.header>
        </:header>

        <.panel
          title="Operation Invocations"
          description="Each entry is one call through the platform Operation boundary."
          icon="hero-play-circle"
        >
          <div :if={@invocations == []} class="text-sm text-text-muted">
            No invocations recorded yet. Run an Operation from an Application Instance to see activity here.
          </div>

          <div :if={@invocations != []} class="divide-y divide-border">
            <div
              :for={inv <- @invocations}
              class="flex items-start justify-between gap-4 py-3 text-sm"
            >
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-medium text-text">
                    {Map.get(@operation_names, inv.operation_id, inv.operation_id)}
                  </span>
                  <.status_pill status={inv.status} />
                </div>
                <p class="mt-1 truncate text-xs text-text-muted">
                  {inv.operation_id}
                  <span :if={inv.run_id}> · Run {short_id(inv.run_id)}</span>
                </p>
              </div>
              <div class="shrink-0 text-end">
                <a
                  href={"/applications/#{inv.application_instance_id}"}
                  class="block max-w-48 truncate text-xs font-medium text-primary hover:underline"
                >
                  {inv.application_instance && inv.application_instance.name}
                </a>
                <span class="mt-1 block text-xs text-text-muted">
                  {format_time(inv.started_at)}
                  <span :if={inv.completed_at}>
                    · {duration(inv.started_at, inv.completed_at)}
                  </span>
                </span>
              </div>
            </div>
          </div>
        </.panel>
      </.surface>
    </Layouts.app>
    """
  end

  attr :status, :any, required: true

  defp status_pill(assigns) do
    ~H"""
    <span class={[
      "inline-flex rounded-full px-2 py-0.5 text-[11px] font-medium",
      status_class(@status)
    ]}>
      {@status |> to_string() |> String.replace("_", " ") |> String.capitalize()}
    </span>
    """
  end

  defp status_class(s) when s in [:succeeded], do: "bg-primary-subtle text-primary"
  defp status_class(s) when s in [:running], do: "bg-surface-raised text-text-muted"
  defp status_class(s) when s in [:failed], do: "bg-danger/10 text-danger"
  defp status_class(_), do: "bg-surface-raised text-text-muted"

  defp format_time(nil), do: "—"

  defp format_time(%DateTime{} = dt),
    do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")

  defp short_id(nil), do: "—"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp duration(started_at, completed_at) do
    ms = DateTime.diff(completed_at, started_at, :millisecond)
    if ms < 1000, do: "#{ms}ms", else: "#{Float.round(ms / 1000, 1)}s"
  end
end
