defmodule Contexla.Applications.ContentIntegrityMonitor.Web.OverviewLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.{Instance, Runtime}
  alias Contexla.Applications.ContentIntegrityMonitor.Monitors

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)
    socket = socket |> assign(:instance, instance) |> load()

    if connected?(socket) && map_size(socket.assigns.overview.active_runs) > 0 do
      Process.send_after(self(), :poll, 2_000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:poll, socket) do
    socket = load(socket)

    if map_size(socket.assigns.overview.active_runs) > 0 do
      Process.send_after(self(), :poll, 2_000)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("run", %{"monitor_id" => monitor_id}, socket) do
    instance = socket.assigns.instance

    case Runtime.invoke_operation(
           instance.actor_id,
           instance.id,
           "integrity.run",
           %{"monitor_id" => monitor_id}
         ) do
      {:ok, _result, _invocation} ->
        Process.send_after(self(), :poll, 2_000)
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
    <.application_frame
      id="integrity-overview"
      icon="hero-shield-check"
      title={@instance.name}
      flash={assigns[:flash]}
    >
      <:actions>
        <a
          href={"/applications/#{@instance.id}/settings"}
          class="grid size-8 place-items-center text-text-muted hover:text-text"
          aria-label="Instance settings"
        >
          <.icon name="hero-cog-6-tooth" class="size-4" />
        </a>
      </:actions>
      <:navigation>
        <.tabs id="integrity-navigation">
          <:tab label="Overview" icon="hero-home" navigate={"/applications/#{@instance.id}"} selected />
          <:tab label="Monitors" icon="hero-signal" navigate={"/applications/#{@instance.id}/monitors"} />
        </.tabs>
      </:navigation>

      <div :if={@overview.monitors == []} class="mt-6">
        <.empty_state
          title="No monitors configured"
          description="Add a monitor to start tracking content integrity across your authoritative sources and delivery systems."
        >
          <:actions>
            <.link
              navigate={"/applications/#{@instance.id}/monitors"}
              class="btn btn-primary"
            >
              Go to Monitors
            </.link>
          </:actions>
        </.empty_state>
      </div>

      <div :if={@overview.monitors != []} class="mt-6 space-y-4">
        <div :for={monitor <- @overview.monitors} id={"monitor-#{monitor.id}"}>
          <% active = @overview.active_runs[monitor.id] %>
          <% is_collection = not is_nil(monitor.scope_source_id) %>
          <% summary = @overview.summaries[monitor.id] %>
          <% matrix = @overview.matrices[monitor.id] %>

          <.panel
            title={monitor.name}
            description={panel_description(is_collection, summary, matrix, active)}
          >
            <:actions>
              <.button
                id={"run-monitor-#{monitor.id}"}
                phx-click="run"
                phx-value-monitor_id={monitor.id}
                size="sm"
                variant="primary"
              >
                Run
              </.button>
            </:actions>

            <div :if={active} class="flex items-center gap-2 py-6 text-sm text-text-muted">
              <.icon name="hero-arrow-path" class="size-4 animate-spin" />
              <span>Run in progress…</span>
            </div>

            <%!-- Collection monitor — aggregate summary --%>
            <div :if={!active && is_collection && summary && summary.run != nil} class="space-y-3">
              <div class="flex flex-wrap gap-2">
                <.state_count_badge
                  :for={{state_key, count} <- Enum.sort(summary.states)}
                  :if={count > 0}
                  state={String.to_existing_atom(state_key)}
                  count={count}
                />
              </div>
              <p :if={summary.open_issues > 0} class="text-xs text-text-muted">
                {summary.open_issues} open issue(s) · {summary.entity_count} entities checked
              </p>
              <p :if={summary.open_issues == 0} class="text-xs text-text-muted">
                No open issues · {summary.entity_count} entities checked
              </p>
            </div>

            <%!-- Collection monitor — no results yet --%>
            <div :if={!active && is_collection && (is_nil(summary) || is_nil(summary.run))} class="py-6 text-sm text-text-muted">
              No results yet. Click <strong class="font-medium text-text">Run</strong>
              to check content integrity across all sources.
            </div>

            <%!-- Single-entity monitor — fact × source matrix --%>
            <div :if={!active && !is_collection && matrix && matrix.run == nil} class="py-6 text-sm text-text-muted">
              No results yet. Click <strong class="font-medium text-text">Run</strong>
              to check content integrity across all sources.
            </div>

            <div :if={!active && !is_collection && matrix && matrix.run != nil} class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="border-b border-border">
                    <th class="pb-3 pr-8 text-left text-xs font-medium uppercase tracking-wide text-text-muted">
                      Fact
                    </th>
                    <th
                      :for={source <- matrix.sources}
                      class="pb-3 pr-4 text-left text-xs font-medium uppercase tracking-wide text-text-muted"
                    >
                      <span class="flex items-center gap-1.5 whitespace-nowrap">
                        {source.name}
                        <span
                          :if={source.role == :source}
                          class="rounded bg-primary-subtle px-1 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-primary"
                        >
                          source
                        </span>
                      </span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border/60">
                  <tr :for={fact <- matrix.facts}>
                    <td class="py-3 pr-8 font-medium text-text">{fact.name}</td>
                    <td :for={source <- matrix.sources} class="py-3 pr-4">
                      <% obs = matrix.cells[{source.id, fact.id}] %>
                      <.integrity_badge state={obs && obs.state} />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </.panel>
        </div>

        <.panel
          :if={unresolved(@overview.issues) != []}
          title="Open issues"
          description="Evidence-backed conditions requiring attention."
        >
          <div class="divide-y divide-border">
            <div
              :for={issue <- unresolved(@overview.issues)}
              id={"issue-#{issue.id}"}
              class="py-4 first:pt-0 last:pb-0"
            >
              <% detail = @overview.issue_details[issue.id] %>
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                  <p class="text-sm font-medium text-text">{issue.fact.name}</p>
                  <p class="mt-0.5 text-xs text-text-muted">
                    {issue.source.name} · {issue.monitor.name}
                    <span :if={issue.ref_id} class="ml-1 font-mono">[{issue.ref_id}]</span>
                  </p>
                </div>
                <.integrity_badge state={issue.kind} />
              </div>
              <dl
                :if={detail.expected || detail.observed}
                class="mt-3 grid gap-2 rounded-lg border border-border bg-surface-raised p-3 sm:grid-cols-2"
              >
                <div>
                  <dt class="text-[11px] font-medium uppercase tracking-wide text-text-muted">
                    Expected
                  </dt>
                  <dd class="mt-1 break-words text-sm text-text">{display_value(detail.expected)}</dd>
                </div>
                <div>
                  <dt class="text-[11px] font-medium uppercase tracking-wide text-text-muted">
                    Found
                  </dt>
                  <dd class="mt-1 break-words text-sm text-text">{display_value(detail.observed)}</dd>
                </div>
              </dl>
              <div class="mt-3 flex flex-wrap items-center gap-2">
                <.button
                  :if={issue.status == :open}
                  id={"acknowledge-issue-#{issue.id}"}
                  phx-click="acknowledge_issue"
                  phx-value-issue_id={issue.id}
                  size="sm"
                  variant="soft"
                >
                  Acknowledge
                </.button>
                <.button
                  id={"resolve-issue-#{issue.id}"}
                  phx-click="resolve_issue"
                  phx-value-issue_id={issue.id}
                  size="sm"
                  variant="ghost"
                >
                  Resolve
                </.button>
                <span class="ml-auto text-xs text-text-muted">
                  First seen {format_time(issue.first_seen_at)} · {issue.occurrence_count} occurrence(s)
                </span>
              </div>
            </div>
          </div>
        </.panel>

        <.panel :if={@overview.runs != []} title="Recent runs">
          <div class="divide-y divide-border">
            <div
              :for={run <- Enum.take(@overview.runs, 6)}
              id={"run-#{run.id}"}
              class="flex items-center justify-between gap-4 py-2.5 first:pt-0 last:pb-0"
            >
              <div>
                <p class="text-sm text-text">{run.monitor.name}</p>
                <p class="text-xs text-text-muted">{format_time(run.inserted_at)}</p>
              </div>
              <.run_status_badge status={run.status} />
            </div>
          </div>
        </.panel>
      </div>
    </.application_frame>
    """
  end

  attr(:state, :atom, default: nil)

  defp integrity_badge(assigns) do
    {css, icon, label} = badge_attrs(assigns.state)
    assigns = assign(assigns, css: css, icon: icon, label: label)

    ~H"""
    <span class={@css}>
      <.icon name={@icon} class="size-3" />
      {@label}
    </span>
    """
  end

  attr(:state, :atom, required: true)
  attr(:count, :integer, required: true)

  defp state_count_badge(assigns) do
    {css, icon, label} = badge_attrs(assigns.state)
    assigns = assign(assigns, css: css, icon: icon, label: label)

    ~H"""
    <span class={@css}>
      <.icon name={@icon} class="size-3" />
      {@count} {@label}
    </span>
    """
  end

  attr(:status, :atom, required: true)

  defp run_status_badge(assigns) do
    {css, label} = run_badge_attrs(assigns.status)
    assigns = assign(assigns, css: css, label: label)

    ~H"""
    <span class={@css}>{@label}</span>
    """
  end

  defp badge_attrs(:healthy), do: {"badge badge-success", "hero-check", "healthy"}
  defp badge_attrs(:pending), do: {"badge badge-warning", "hero-clock", "pending"}
  defp badge_attrs(:overdue), do: {"badge badge-warning", "hero-exclamation-triangle", "overdue"}
  defp badge_attrs(:mismatch), do: {"badge badge-danger", "hero-x-mark", "mismatch"}
  defp badge_attrs(:missing), do: {"badge badge-danger", "hero-minus", "missing"}

  defp badge_attrs(:unavailable),
    do: {"badge badge-neutral", "hero-exclamation-circle", "unavailable"}

  defp badge_attrs(:unknown), do: {"badge badge-neutral", "hero-question-mark-circle", "unknown"}
  defp badge_attrs(nil), do: {"badge badge-neutral", "hero-minus", "—"}

  defp run_badge_attrs(:succeeded), do: {"badge badge-success", "Completed"}
  defp run_badge_attrs(:failed), do: {"badge badge-danger", "Failed"}
  defp run_badge_attrs(:running), do: {"badge badge-warning", "Running"}
  defp run_badge_attrs(:queued), do: {"badge badge-neutral", "Queued"}

  defp panel_description(_is_collection, _summary, _matrix, active) when not is_nil(active),
    do: "Run in progress"

  defp panel_description(true, %{run: nil}, _matrix, _active), do: "Never checked"

  defp panel_description(true, %{run: run}, _matrix, _active),
    do: "Last checked #{format_elapsed(run.completed_at)}"

  defp panel_description(false, _summary, %{run: nil}, _active), do: "Never checked"

  defp panel_description(false, _summary, %{run: run}, _active),
    do: "Last checked #{format_elapsed(run.completed_at)}"

  defp panel_description(_is_collection, nil, nil, _active), do: "Never checked"
  defp panel_description(_is_collection, _summary, _matrix, _active), do: ""

  defp format_elapsed(nil), do: "—"

  defp format_elapsed(dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :minute)

    cond do
      diff < 1 -> "just now"
      diff < 60 -> "#{diff} minute(s) ago"
      diff < 1440 -> "#{div(diff, 60)} hour(s) ago"
      true -> Calendar.strftime(dt, "%Y-%m-%d")
    end
  end

  defp unresolved(issues), do: Enum.reject(issues, &(&1.status == :resolved))

  defp format_time(nil), do: "—"
  defp format_time(dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")

  defp display_value(nil), do: "Not observed"
  defp display_value(value), do: value
end
