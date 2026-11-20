defmodule Contexla.EstateWeb.OverviewLive do
  use ContexlaUI, :live_view

  alias Contexla.ApplicationSDK.{Instance, Runtime}
  alias Contexla.Estate.Assessments

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)

    {:ok,
     socket
     |> assign(:instance, instance)
     |> allow_upload(:snapshot, accept: ~w(.zip), max_entries: 1, max_file_size: 50_000_000)
     |> load_state()}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    imported =
      consume_uploaded_entries(socket, :snapshot, fn %{path: path}, entry ->
        result =
          Runtime.call(:platform, :import_source, [
            socket.assigns.instance.actor_id,
            socket.assigns.instance.id,
            "drupal.assessment.snapshot.v1",
            path,
            [filename: entry.client_name]
          ])

        {:ok, result}
      end)

    case imported do
      [{:ok, _artifact}] ->
        {:noreply, socket |> put_flash(:info, "Snapshot retained.") |> load_state()}

      [{:error, reason}] ->
        {:noreply, put_flash(socket, :error, "Snapshot rejected: #{inspect(reason)}")}

      _ ->
        {:noreply, put_flash(socket, :error, "Choose one Drupal snapshot ZIP.")}
    end
  end

  def handle_event("start-run", %{"artifact-id" => artifact_id}, socket) do
    case Assessments.start_run(socket.assigns.instance, artifact_id) do
      {:ok, _run} ->
        Process.send_after(self(), :refresh, 500)
        {:noreply, socket |> put_flash(:info, "Assessment queued.") |> load_state()}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Run could not start: #{inspect(reason)}")}
    end
  end

  def handle_event(
        "review-finding",
        %{
          "finding-id" => finding_id,
          "review" => %{"status" => status, "rationale" => rationale}
        },
        socket
      ) do
    case Assessments.review_finding(socket.assigns.instance, finding_id, status, rationale) do
      {:ok, _finding} ->
        {:noreply, socket |> put_flash(:info, "Finding review recorded.") |> load_state()}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "A valid status and rationale are required.")}
    end
  end

  def handle_event("add-expert-finding", %{"expert" => params}, socket) do
    case Assessments.add_expert_finding(
           socket.assigns.instance,
           socket.assigns.results.run.id,
           params
         ) do
      {:ok, _finding} ->
        {:noreply, socket |> put_flash(:info, "Expert finding added.") |> load_state()}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Complete the required finding fields.")}
    end
  end

  @impl true
  def handle_info(:refresh, socket) do
    socket = load_state(socket)

    if Enum.any?(socket.assigns.runs, &(&1.status in [:queued, :running])),
      do: Process.send_after(self(), :refresh, 750)

    {:noreply, socket}
  end

  defp load_state(socket) do
    instance = socket.assigns.instance
    runs = Assessments.list_runs(instance)
    completed = Enum.find(runs, &(&1.status == :succeeded))

    socket
    |> assign(
      :artifacts,
      Runtime.call(:platform, :list_artifacts, [instance.actor_id, instance.id])
    )
    |> assign(:runs, runs)
    |> assign(:results, completed && Assessments.results(instance, completed.id))
    |> assign(:expert_form, expert_form())
  end

  defp expert_form do
    to_form(
      %{
        "category" => "technical_debt",
        "severity" => "medium",
        "confidence" => "medium",
        "summary" => "",
        "explanation" => "",
        "recommendation" => ""
      },
      as: :expert
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.surface flash={assigns[:flash]}>
      <:header>
        <.header id="assessment-overview-page-header" icon="hero-clipboard-document-check">
          {@instance.name}
          <:subtitle>{@instance.config["decision"]}</:subtitle>
          <:actions>
            <a
              href={"/applications/#{@instance.id}/settings"}
              class="grid size-8 place-items-center text-text-muted transition-colors hover:text-text"
              aria-label="Instance settings"
            >
              <.icon name="hero-cog-6-tooth" class="size-4" />
            </a>
          </:actions>
        </.header>
      </:header>

      <div class="grid gap-6 lg:grid-cols-[0.8fr_1.2fr]">
        <.panel title="Import evidence" description="Upload an approved Drupal snapshot package." icon="hero-arrow-up-tray">
          <form id="snapshot-upload" phx-submit="upload" class="mt-5 space-y-4">
            <.live_file_input upload={@uploads.snapshot} class="input-field block w-full p-3" />
            <.button type="submit" variant="primary" class="w-full">Validate and retain snapshot</.button>
          </form>
          <div class="mt-6 space-y-3">
            <article :for={artifact <- @artifacts} class="rounded-xl border border-border bg-surface-raised p-4">
              <p class="truncate text-sm font-medium">{artifact.filename}</p>
              <.button phx-click="start-run" phx-value-artifact-id={artifact.id} class="mt-3 btn-outline btn-sm">Start Run</.button>
            </article>
            <p :if={@artifacts == []} class="text-sm text-text-muted">No evidence uploaded.</p>
          </div>
        </.panel>

        <div class="space-y-6">
          <.panel title="Runs" description="Durable assessment executions and their current status." icon="hero-play-circle">
            <div class="mt-4 space-y-2">
              <div :for={run <- @runs} class="flex items-center justify-between rounded-xl border border-border bg-surface-raised px-4 py-3 text-sm">
                <span class="text-text-muted">{run.inserted_at}</span><span class="badge badge-success">{run.status}</span>
              </div>
              <p :if={@runs == []} class="text-sm text-text-muted">No Runs yet.</p>
            </div>
          </.panel>

          <.panel :if={@results} title="Latest result" icon="hero-chart-bar-square">
            <:actions><a href={"/applications/#{@instance.id}/report?run_id=#{@results.run.id}"} class="text-sm font-semibold text-primary">View report →</a></:actions>
            <div class="mt-5 grid grid-cols-3 gap-3">
              <.stat label="Inventory" value={length(@results.inventory_items)} />
              <.stat label="Findings" value={length(@results.findings)} />
              <.stat label="Evidence" value={length(@results.evidence_items)} />
            </div>

            <details class="mt-6 rounded-xl border border-dashed border-border-strong p-4">
              <summary class="cursor-pointer text-sm font-semibold text-primary">Add expert finding</summary>
              <.form for={@expert_form} id="expert-finding" phx-submit="add-expert-finding" class="mt-4 grid gap-3 sm:grid-cols-2">
                <input name={@expert_form[:summary].name} required placeholder="Summary" class="input-field" />
                <input name={@expert_form[:category].name} value={@expert_form[:category].value} required placeholder="Category" class="input-field" />
                <select name={@expert_form[:severity].name} class="input-field">
                  <option :for={value <- ~w(info low medium high critical)} value={value} selected={value == "medium"}>{value}</option>
                </select>
                <select name={@expert_form[:confidence].name} class="input-field">
                  <option :for={value <- ~w(low medium high)} value={value} selected={value == "medium"}>{value}</option>
                </select>
                <textarea name={@expert_form[:explanation].name} required placeholder="Explanation" class="input-field min-h-24 sm:col-span-2"></textarea>
                <textarea name={@expert_form[:recommendation].name} required placeholder="Recommendation" class="input-field min-h-24 sm:col-span-2"></textarea>
                <.button variant="primary" class="sm:col-span-2">Add attributed finding</.button>
              </.form>
            </details>

            <div class="mt-6 space-y-3">
              <article :for={finding <- @results.findings} class="rounded-xl border border-border p-4">
                <p class="text-xs uppercase text-text-muted">{finding.origin} · {finding.severity} · {finding.status}</p>
                <h3 class="mt-1 font-semibold">{finding.summary}</h3>
                <p class="mt-2 text-sm text-text-muted">{finding.explanation}</p>
                <form id={"review-#{finding.id}"} phx-submit="review-finding" class="mt-4 grid gap-2 border-t border-border pt-4 sm:grid-cols-[0.6fr_1.4fr_auto]">
                  <input type="hidden" name="finding-id" value={finding.id} />
                  <select name="review[status]" class="input-field">
                    <option :for={value <- ~w(accepted suppressed resolved open)} value={value}>{value}</option>
                  </select>
                  <input name="review[rationale]" required minlength="3" placeholder="Review rationale" class="input-field" />
                  <.button class="btn-outline">Record</.button>
                </form>
              </article>
            </div>
          </.panel>
        </div>
      </div>
    </.surface>
    """
  end
end
