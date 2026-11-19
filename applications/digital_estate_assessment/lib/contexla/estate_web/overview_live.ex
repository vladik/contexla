defmodule Contexla.EstateWeb.OverviewLive do
  use Phoenix.LiveView
  import Phoenix.Component

  alias Contexla.ApplicationSDK.{Instance, Runtime}
  alias Contexla.Estate.Assessments

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = instance_from_session(data)

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

  defp instance_from_session(data) do
    %Instance{
      id: data["id"],
      application_id: data["application_id"],
      application_version: data["application_version"],
      name: data["name"],
      status: data["status"],
      config: data["config"],
      actor_id: data["actor_id"]
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <a href="/" class="text-sm font-medium text-indigo-600">← Applications</a>
      <header class="mt-5 border-b border-base-300 pb-7">
        <p class="text-sm font-semibold uppercase tracking-[0.18em] text-indigo-600">Digital Estate Assessment</p>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">{@instance.name}</h1>
        <p class="mt-2 text-base-content/60">{@instance.config["decision"]}</p>
      </header>

      <div class="mt-8 grid gap-6 lg:grid-cols-[0.8fr_1.2fr]">
        <section class="rounded-2xl border border-base-300 p-6">
          <h2 class="text-lg font-semibold">Import evidence</h2>
          <form id="snapshot-upload" phx-submit="upload" class="mt-5 space-y-4">
            <.live_file_input upload={@uploads.snapshot} class="block w-full rounded-xl border border-base-300 p-3" />
            <button class="w-full rounded-xl bg-indigo-600 px-4 py-3 font-semibold text-white">Validate and retain snapshot</button>
          </form>
          <div class="mt-6 space-y-3">
            <article :for={artifact <- @artifacts} class="rounded-xl bg-base-200 p-4">
              <p class="truncate text-sm font-medium">{artifact.filename}</p>
              <button phx-click="start-run" phx-value-artifact-id={artifact.id} class="mt-3 rounded-lg bg-base-100 px-3 py-2 text-sm font-semibold">Start Run</button>
            </article>
            <p :if={@artifacts == []} class="text-sm text-base-content/50">No evidence uploaded.</p>
          </div>
        </section>

        <div class="space-y-6">
          <section class="rounded-2xl border border-base-300 p-6">
            <h2 class="text-lg font-semibold">Runs</h2>
            <div class="mt-4 space-y-2">
              <div :for={run <- @runs} class="flex items-center justify-between rounded-xl bg-base-200 px-4 py-3 text-sm">
                <span>{run.inserted_at}</span><span class="font-semibold">{run.status}</span>
              </div>
              <p :if={@runs == []} class="text-sm text-base-content/50">No Runs yet.</p>
            </div>
          </section>

          <section :if={@results} class="rounded-2xl border border-base-300 p-6">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold">Latest result</h2>
              <a href={"/applications/#{@instance.id}/report?run_id=#{@results.run.id}"} class="text-sm font-semibold text-indigo-600">View report →</a>
            </div>
            <div class="mt-5 grid grid-cols-3 gap-3">
              <div class="rounded-xl bg-base-200 p-4"><strong class="text-2xl">{length(@results.inventory_items)}</strong><span class="mt-1 block text-xs uppercase">Inventory</span></div>
              <div class="rounded-xl bg-base-200 p-4"><strong class="text-2xl">{length(@results.findings)}</strong><span class="mt-1 block text-xs uppercase">Findings</span></div>
              <div class="rounded-xl bg-base-200 p-4"><strong class="text-2xl">{length(@results.evidence_items)}</strong><span class="mt-1 block text-xs uppercase">Evidence</span></div>
            </div>

            <details class="mt-6 rounded-xl border border-dashed border-base-300 p-4">
              <summary class="cursor-pointer text-sm font-semibold text-indigo-600">Add expert finding</summary>
              <.form for={@expert_form} id="expert-finding" phx-submit="add-expert-finding" class="mt-4 grid gap-3 sm:grid-cols-2">
                <input name={@expert_form[:summary].name} required placeholder="Summary" class="rounded-lg border border-base-300 bg-base-100 px-3 py-2" />
                <input name={@expert_form[:category].name} value={@expert_form[:category].value} required placeholder="Category" class="rounded-lg border border-base-300 bg-base-100 px-3 py-2" />
                <select name={@expert_form[:severity].name} class="rounded-lg border border-base-300 bg-base-100 px-3 py-2">
                  <option :for={value <- ~w(info low medium high critical)} value={value} selected={value == "medium"}>{value}</option>
                </select>
                <select name={@expert_form[:confidence].name} class="rounded-lg border border-base-300 bg-base-100 px-3 py-2">
                  <option :for={value <- ~w(low medium high)} value={value} selected={value == "medium"}>{value}</option>
                </select>
                <textarea name={@expert_form[:explanation].name} required placeholder="Explanation" class="min-h-24 rounded-lg border border-base-300 bg-base-100 px-3 py-2 sm:col-span-2"></textarea>
                <textarea name={@expert_form[:recommendation].name} required placeholder="Recommendation" class="min-h-24 rounded-lg border border-base-300 bg-base-100 px-3 py-2 sm:col-span-2"></textarea>
                <button class="rounded-lg bg-indigo-600 px-4 py-2 font-semibold text-white sm:col-span-2">Add attributed finding</button>
              </.form>
            </details>

            <div class="mt-6 space-y-3">
              <article :for={finding <- @results.findings} class="rounded-xl border border-base-300 p-4">
                <p class="text-xs uppercase text-base-content/50">{finding.origin} · {finding.severity} · {finding.status}</p>
                <h3 class="mt-1 font-semibold">{finding.summary}</h3>
                <p class="mt-2 text-sm text-base-content/65">{finding.explanation}</p>
                <form id={"review-#{finding.id}"} phx-submit="review-finding" class="mt-4 grid gap-2 border-t border-base-200 pt-4 sm:grid-cols-[0.6fr_1.4fr_auto]">
                  <input type="hidden" name="finding-id" value={finding.id} />
                  <select name="review[status]" class="rounded-lg border border-base-300 bg-base-100 px-3 py-2">
                    <option :for={value <- ~w(accepted suppressed resolved open)} value={value}>{value}</option>
                  </select>
                  <input name="review[rationale]" required minlength="3" placeholder="Review rationale" class="rounded-lg border border-base-300 bg-base-100 px-3 py-2" />
                  <button class="rounded-lg border border-base-300 px-4 py-2 font-semibold">Record</button>
                </form>
              </article>
            </div>
          </section>
        </div>
      </div>
    </main>
    """
  end
end
