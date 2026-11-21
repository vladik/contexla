defmodule ContexlaWeb.OperationsLive do
  use ContexlaWeb, :live_view

  alias Contexla.Operations

  @refresh_interval 15_000

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Operations")
      |> load_snapshot()

    if connected?(socket), do: schedule_refresh()
    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket), do: {:noreply, load_snapshot(socket)}

  @impl true
  def handle_info(:refresh_operations, socket) do
    schedule_refresh()
    {:noreply, load_snapshot(socket)}
  end

  defp load_snapshot(socket) do
    {:ok, snapshot} = Operations.snapshot(socket.assigns.current_scope)
    assign(socket, :snapshot, snapshot)
  end

  defp schedule_refresh, do: Process.send_after(self(), :refresh_operations, @refresh_interval)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.surface>
        <:header>
          <.header id="operations-header" icon="hero-command-line">
            Operations
            <:subtitle>Installation health, execution activity, and support references</:subtitle>
            <:actions>
              <span class="hidden text-xs text-text-muted sm:inline">
                Updated {format_time(@snapshot.captured_at)}
              </span>
              <UIButton.button phx-click="refresh" size="sm">
                <.icon name="hero-arrow-path" class="size-4" /> Refresh
              </UIButton.button>
              <UIButton.button href="/operations/support-bundle" variant="primary" size="sm">
                <.icon name="hero-arrow-down-tray" class="size-4" /> Support bundle
              </UIButton.button>
            </:actions>
          </.header>
        </:header>

        <div class="space-y-4">
          <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <.stat
              label="Platform readiness"
              value={status_label(@snapshot.diagnostics.status)}
              hint="Database, storage, and runtime registries"
            />
            <.stat
              label="Application Instances"
              value={@snapshot.counts.instances}
              hint="Configured on this installation"
            />
            <.stat
              label="Active execution"
              value={@snapshot.counts.running_operations + @snapshot.counts.running_capabilities}
              hint="Operation and Capability Invocations"
            />
            <.stat
              label="Recorded failures"
              value={
                @snapshot.counts.failed_operations + @snapshot.counts.failed_capabilities +
                  @snapshot.counts.failed_jobs
              }
              hint="Retained failures; not a rolling time window"
            />
          </div>

          <div class="grid gap-4 xl:grid-cols-2">
            <.panel
              title="System checks"
              description="The same bounded checks used by the readiness endpoint and release diagnostics."
              icon="hero-heart"
            >
              <div class="divide-y divide-border">
                <div
                  :for={{name, status} <- Enum.sort(@snapshot.diagnostics.checks)}
                  class="flex items-center justify-between gap-4 py-2.5 first:pt-0 last:pb-0"
                >
                  <span class="text-sm text-text">{humanize(name)}</span>
                  <.status_pill status={status} />
                </div>
              </div>
            </.panel>

            <.panel
              title="Installed runtime"
              description="Trusted packages and executable contracts currently registered."
              icon="hero-cube-transparent"
            >
              <dl class="grid grid-cols-2 gap-3 text-sm">
                <.runtime_count label="Applications" value={length(@snapshot.packages.applications)} />
                <.runtime_count label="Integrations" value={length(@snapshot.packages.integrations)} />
                <.runtime_count label="Capabilities" value={length(@snapshot.packages.capabilities)} />
                <.runtime_count label="Processors" value={length(@snapshot.packages.processors)} />
              </dl>
              <div
                :if={@snapshot.packages.applications != []}
                class="mt-4 border-t border-border pt-3"
              >
                <div
                  :for={application <- @snapshot.packages.applications}
                  class="flex items-center justify-between gap-4 py-1.5"
                >
                  <span class="min-w-0">
                    <span class="block truncate text-sm font-medium text-text">{application.name}</span>
                    <span class="block truncate text-xs text-text-muted">
                      {application.id} · {application.version}
                    </span>
                  </span>
                  <.status_pill status={if application.running, do: :running, else: :stopped} />
                </div>
              </div>
            </.panel>
          </div>

          <.activity_panel
            title="Application Operations"
            description="Recent calls through the authoritative Application Operation boundary."
            icon="hero-play-circle"
            empty={@snapshot.operation_invocations == []}
          >
            <div
              :for={invocation <- @snapshot.operation_invocations}
              class="flex items-start justify-between gap-4 py-3 text-sm"
            >
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-medium text-text">{invocation.operation_id}</span>
                  <.status_pill status={invocation.status} />
                </div>
                <p class="mt-1 truncate text-xs text-text-muted">
                  {invocation.application_id} · {invocation.application_version}
                  <span :if={invocation.run_id}> · Run {short_id(invocation.run_id)}</span>
                </p>
                <p :if={error_code(invocation.error)} class="mt-1 text-xs text-danger">
                  {error_code(invocation.error)}
                </p>
              </div>
              <div class="shrink-0 text-end">
                <a
                  href={"/applications/#{invocation.application_instance_id}"}
                  class="block max-w-48 truncate text-xs font-medium text-primary hover:underline"
                >
                  {invocation.application_instance.name}
                </a>
                <span class="mt-1 block text-xs text-text-muted">
                  {format_time(invocation.started_at)} · {short_id(invocation.id)}
                </span>
              </div>
            </div>
          </.activity_panel>

          <div class="grid gap-4 xl:grid-cols-2">
            <.activity_panel
              title="Capability Invocations"
              description="Recent Processor executions through resolved Capability Bindings."
              icon="hero-bolt"
              empty={@snapshot.capability_invocations == []}
            >
              <div
                :for={invocation <- @snapshot.capability_invocations}
                class="flex items-start justify-between gap-4 py-3 text-sm"
              >
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="truncate font-medium text-text">{invocation.capability.name}</span>
                    <.status_pill status={invocation.status} />
                  </div>
                  <p class="mt-1 truncate text-xs text-text-muted">
                    {invocation.processor.key} · {invocation.processor.version}
                  </p>
                  <p :if={error_code(invocation.error)} class="mt-1 text-xs text-danger">
                    {error_code(invocation.error)}
                  </p>
                </div>
                <div class="shrink-0 text-end text-xs text-text-muted">
                  <a
                    :if={invocation.application_instance}
                    href={"/applications/#{invocation.application_instance_id}"}
                    class="block max-w-40 truncate font-medium text-primary hover:underline"
                  >
                    {invocation.application_instance.name}
                  </a>
                  <span class="mt-1 block">{format_time(invocation.started_at)}</span>
                  <span class="block">{short_id(invocation.id)}</span>
                </div>
              </div>
            </.activity_panel>

            <.activity_panel
              title="Background Jobs"
              description="Recent Oban jobs without arguments or exception details."
              icon="hero-queue-list"
              empty={@snapshot.jobs == []}
            >
              <div
                :for={job <- @snapshot.jobs}
                class="flex items-start justify-between gap-4 py-3 text-sm"
              >
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="truncate font-medium text-text">{worker_name(job.worker)}</span>
                    <.status_pill status={job.state} />
                  </div>
                  <p class="mt-1 text-xs text-text-muted">
                    Queue {job.queue} · Attempt {job.attempt}/{job.max_attempts}
                  </p>
                </div>
                <div class="shrink-0 text-end text-xs text-text-muted">
                  <span class="block">{format_time(job_time(job))}</span>
                  <span class="block">Job {job.id}</span>
                </div>
              </div>
            </.activity_panel>
          </div>

          <.activity_panel
            title="Audit Activity"
            description="Recent append-only installation and Application Instance lifecycle events."
            icon="hero-shield-check"
            empty={@snapshot.audit_events == []}
          >
            <div
              :for={event <- @snapshot.audit_events}
              class="flex items-start justify-between gap-4 py-3 text-sm"
            >
              <div class="min-w-0">
                <p class="truncate font-medium text-text">{event.action}</p>
                <p class="mt-1 truncate text-xs text-text-muted">
                  {event.subject_type} · {event.subject_id}
                </p>
              </div>
              <div class="shrink-0 text-end text-xs text-text-muted">
                <a
                  :if={event.application_instance}
                  href={"/applications/#{event.application_instance_id}"}
                  class="block max-w-48 truncate font-medium text-primary hover:underline"
                >
                  {event.application_instance.name}
                </a>
                <span class="block">{event.actor_user.email}</span>
                <span class="block">{format_time(event.inserted_at)} · #{event.sequence}</span>
              </div>
            </div>
          </.activity_panel>

          <p class="px-1 text-xs leading-5 text-text-muted">
            This console intentionally excludes credentials, invocation payloads, artifact contents,
            job arguments, and internal exception text. Use the displayed reference IDs to correlate
            sanitized records with installation logs.
          </p>
        </div>
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
      {status_label(@status)}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true

  defp runtime_count(assigns) do
    ~H"""
    <div class="rounded-xl bg-surface-raised px-3 py-2.5">
      <dt class="text-xs text-text-muted">{@label}</dt>
      <dd class="mt-0.5 text-lg font-semibold text-text">{@value}</dd>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :icon, :string, required: true
  attr :empty, :boolean, required: true
  slot :inner_block, required: true

  defp activity_panel(assigns) do
    ~H"""
    <.panel title={@title} description={@description} icon={@icon}>
      <div :if={@empty} class="text-sm text-text-muted">
        No activity recorded.
      </div>
      <div :if={!@empty} class="divide-y divide-border">
        {render_slot(@inner_block)}
      </div>
    </.panel>
    """
  end

  defp status_class(status) when status in [:ok, :succeeded, :completed, :running],
    do: "bg-primary-subtle text-primary"

  defp status_class(status)
       when status in [:available, :scheduled, :retryable, "available", "scheduled", "retryable"],
       do: "bg-surface-raised text-text-muted"

  defp status_class(status)
       when status in [:error, :failed, :timed_out, :discarded, :stopped, "discarded"],
       do: "bg-danger/10 text-danger"

  defp status_class(_status), do: "bg-surface-raised text-text-muted"

  defp status_label(status) when is_atom(status), do: status |> Atom.to_string() |> humanize()
  defp status_label(status) when is_binary(status), do: humanize(status)

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_time(nil), do: "—"

  defp format_time(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp format_time(%NaiveDateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")

  defp short_id(nil), do: "—"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp error_code(nil), do: nil
  defp error_code(%{"code" => code}) when is_binary(code), do: code
  defp error_code(%{code: code}) when is_binary(code), do: code
  defp error_code(_error), do: "operation_failed"

  defp worker_name(worker), do: worker |> String.split(".") |> List.last()

  defp job_time(job),
    do:
      job.completed_at || job.discarded_at || job.cancelled_at || job.attempted_at ||
        job.scheduled_at || job.inserted_at
end
