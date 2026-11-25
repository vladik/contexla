defmodule Contexla.Applications.ContentIntegrityMonitor.Web.CollectionLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.Instance
  alias Contexla.Applications.ContentIntegrityMonitor.Monitors

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)
    {:ok, assign(socket, instance: instance, overview: Monitors.overview(instance))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.application_frame id="integrity-monitors" icon="hero-shield-check" title={@instance.name} subtitle="Monitors" flash={assigns[:flash]}>
      <:navigation>
        <.tabs id="integrity-navigation">
          <:tab label="Overview" icon="hero-home" navigate={"/applications/#{@instance.id}"} />
          <:tab label="Monitors" icon="hero-signal" navigate={"/applications/#{@instance.id}/monitors"} selected />
        </.tabs>
      </:navigation>
      <div :if={@overview.monitors == []}><.empty_state title="No Monitors configured" description="Create the bounded demonstration from Overview to begin." /></div>
      <div :if={@overview.monitors != []} class="space-y-4">
        <.panel :for={monitor <- @overview.monitors} title={monitor.name} description={monitor.entity_key}>
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <div :for={source <- monitor.sources} class="rounded-xl border border-border bg-surface-raised p-3">
              <p class="text-sm font-medium text-text">{source.name}</p>
              <p class="mt-1 text-xs text-text-muted">{humanize(source.role)} · {String.upcase(to_string(source.format))}</p>
              <p class="mt-2 truncate text-xs text-text-muted">{source.url}</p>
            </div>
          </div>
        </.panel>
      </div>
    </.application_frame>
    """
  end

  defp humanize(value),
    do: value |> to_string() |> String.replace("_", " ") |> String.capitalize()
end
