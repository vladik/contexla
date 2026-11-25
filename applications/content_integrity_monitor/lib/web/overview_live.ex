defmodule Contexla.Applications.ContentIntegrityMonitor.Web.OverviewLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.{Instance, Runtime}
  alias Contexla.Applications.ContentIntegrityMonitor.Monitors

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)
    {:ok, socket |> assign(:instance, instance) |> load()}
  end

  @impl true
  def handle_event("setup_demo", _params, socket) do
    instance = socket.assigns.instance

    case Runtime.invoke_operation(instance.actor_id, instance.id, "integrity.demo_setup", %{},
           approved: true
         ) do
      {:ok, _result, _invocation} ->
        {:noreply, socket |> load() |> put_flash(:info, "Demonstration Monitor created.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "The demonstration Monitor could not be created.")}

      {:error, _reason, _invocation} ->
        {:noreply, put_flash(socket, :error, "The demonstration Monitor could not be created.")}
    end
  end

  def handle_event("run", %{"monitor_id" => monitor_id}, socket) do
    instance = socket.assigns.instance

    case Runtime.invoke_operation(
           instance.actor_id,
           instance.id,
           "integrity.run",
           %{"monitor_id" => monitor_id}
         ) do
      {:ok, _result, _invocation} ->
        {:noreply, socket |> load() |> put_flash(:info, "Integrity Run queued.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "The integrity Run could not be started.")}

      {:error, _reason, _invocation} ->
        {:noreply, put_flash(socket, :error, "The integrity Run could not be started.")}
    end
  end

  def handle_event("acknowledge_issue", %{"issue_id" => issue_id}, socket) do
    transition_issue(socket, "integrity.issue.acknowledge", issue_id, "Issue acknowledged.")
  end

  def handle_event("resolve_issue", %{"issue_id" => issue_id}, socket) do
    transition_issue(socket, "integrity.issue.resolve", issue_id, "Issue resolved.")
  end

  defp load(socket) do
    assign(socket, :overview, Monitors.overview(socket.assigns.instance))
  end

  defp transition_issue(socket, operation_id, issue_id, success_message) do
    instance = socket.assigns.instance

    case Runtime.invoke_operation(instance.actor_id, instance.id, operation_id, %{
           "issue_id" => issue_id
         }) do
      {:ok, _result, _invocation} ->
        {:noreply, socket |> load() |> put_flash(:info, success_message)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "The Issue could not be updated.")}

      {:error, _reason, _invocation} ->
        {:noreply, put_flash(socket, :error, "The Issue could not be updated.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.application_frame id="integrity-overview" icon="hero-shield-check" title={@instance.name} subtitle={@instance.config["purpose"]} flash={assigns[:flash]}>
      <:actions>
        <a href={"/applications/#{@instance.id}/settings"} class="grid size-8 place-items-center text-text-muted hover:text-text" aria-label="Instance settings"><.icon name="hero-cog-6-tooth" class="size-4" /></a>
      </:actions>
      <:navigation>
        <.tabs id="integrity-navigation">
          <:tab label="Overview" icon="hero-home" navigate={"/applications/#{@instance.id}"} selected />
          <:tab label="Monitors" icon="hero-signal" navigate={"/applications/#{@instance.id}/monitors"} />
        </.tabs>
      </:navigation>

      <div class="grid gap-4 sm:grid-cols-3">
        <.stat label="Monitors" value={length(@overview.monitors)} />
        <.stat label="Open issues" value={unresolved_count(@overview.issues)} />
        <.stat label="Runs" value={length(@overview.runs)} />
      </div>

      <div :if={@overview.monitors == []} class="mt-6">
        <.empty_state title="Create the first integrity Monitor" description="Use the bounded program-content demonstration to prove acquisition, extraction, comparison, evidence, and Issue history.">
          <:actions><.button id="setup-integrity-demo" phx-click="setup_demo" variant="primary">Create demonstration</.button></:actions>
        </.empty_state>
      </div>

      <div :if={@overview.monitors != []} class="mt-6 grid gap-4 xl:grid-cols-[1fr_1.35fr]">
        <.panel title="Monitors" description="Configured integrity questions and their latest execution.">
          <div class="divide-y divide-border">
            <div :for={monitor <- @overview.monitors} id={"monitor-#{monitor.id}"} class="flex items-start justify-between gap-4 py-3 first:pt-0 last:pb-0">
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-text">{monitor.name}</p>
                <p class="mt-1 text-xs text-text-muted">{monitor.entity_key} · {length(monitor.sources)} sources · {length(monitor.facts)} facts</p>
              </div>
              <.button id={"run-monitor-#{monitor.id}"} phx-click="run" phx-value-monitor_id={monitor.id} size="sm" variant="primary">Run</.button>
            </div>
          </div>
        </.panel>

        <.panel title="Current issues" description="Evidence-backed conditions requiring operational attention.">
          <div :if={unresolved(@overview.issues) == []} class="text-sm text-text-muted">No open issues have been recorded.</div>
          <div :if={unresolved(@overview.issues) != []} class="divide-y divide-border">
            <div :for={issue <- unresolved(@overview.issues)} id={"issue-#{issue.id}"} class="py-3 first:pt-0 last:pb-0">
              <% detail = @overview.issue_details[issue.id] %>
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm font-medium text-text">{issue.summary}</p>
                <span class="rounded-full bg-danger/10 px-2 py-0.5 text-[11px] font-medium text-danger">{humanize(issue.kind)}</span>
              </div>
              <dl class="mt-3 grid gap-2 rounded-lg border border-border bg-surface-raised p-3 sm:grid-cols-2">
                <div>
                  <dt class="text-[11px] font-medium uppercase tracking-wide text-text-muted">Authoritative</dt>
                  <dd class="mt-1 text-sm text-text">{display_value(detail.expected)}</dd>
                </div>
                <div>
                  <dt class="text-[11px] font-medium uppercase tracking-wide text-text-muted">Observed in {issue.source.name}</dt>
                  <dd class="mt-1 text-sm text-text">{display_value(detail.observed)}</dd>
                </div>
              </dl>
              <div class="mt-2 flex items-center gap-2">
                <.button :if={issue.status == :open} id={"acknowledge-issue-#{issue.id}"} phx-click="acknowledge_issue" phx-value-issue_id={issue.id} size="sm" variant="soft">Acknowledge</.button>
                <.button id={"resolve-issue-#{issue.id}"} phx-click="resolve_issue" phx-value-issue_id={issue.id} size="sm" variant="ghost">Resolve</.button>
              </div>
              <p :if={detail.evidence} class="mt-1 text-xs text-text-muted">
                Evidence {short_id(detail.evidence.response_sha256)} · Tool Invocation {short_id(detail.evidence.tool_invocation_id)} · observed {format_time(detail.observed_at)}
              </p>
              <p class="mt-1 text-xs text-text-muted">{issue.monitor.name} · last seen {format_time(issue.last_seen_at)} · {issue.occurrence_count} occurrence(s)</p>
            </div>
          </div>
        </.panel>
      </div>

      <div :if={@overview.runs != []} class="mt-4">
        <.panel title="Recent Runs" description="Durable execution history retained by the Application.">
          <div class="divide-y divide-border">
            <div :for={run <- @overview.runs} id={"run-#{run.id}"} class="flex items-center justify-between gap-4 py-2.5 first:pt-0 last:pb-0">
              <div><p class="text-sm font-medium text-text">{run.monitor.name}</p><p class="text-xs text-text-muted">{format_time(run.inserted_at)} · {String.slice(run.id, 0, 8)}</p></div>
              <span class="rounded-full bg-surface-raised px-2 py-0.5 text-[11px] font-medium text-text-muted">{humanize(run.status)}</span>
            </div>
          </div>
        </.panel>
      </div>
    </.application_frame>
    """
  end

  defp unresolved(issues), do: Enum.reject(issues, &(&1.status == :resolved))
  defp unresolved_count(issues), do: issues |> unresolved() |> length()

  defp humanize(value),
    do: value |> to_string() |> String.replace("_", " ") |> String.capitalize()

  defp format_time(nil), do: "—"
  defp format_time(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
  defp display_value(nil), do: "Not observed"
  defp display_value(value), do: value
  defp short_id(nil), do: "—"
  defp short_id(value), do: String.slice(value, 0, 12)
end
