defmodule Contexla.Applications.DigitalEstateAssessment.Web.ReportLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.Instance
  alias Contexla.Applications.DigitalEstateAssessment.Assessments

  @impl true
  def mount(
        _params,
        %{"instance" => data, "surface_params" => %{"run_id" => run_id}},
        socket
      ) do
    instance = Instance.from_session!(data)
    {:ok, assign(socket, instance: instance, report: Assessments.report(instance, run_id))}
  end

  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)

    {:ok,
     socket
     |> put_flash(:error, "Choose a completed Run before opening its report.")
     |> redirect(to: "/applications/#{instance.id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.application_frame
      id="assessment-report-page-header"
      icon="hero-document-chart-bar"
      title={@report["assessment"]["name"]}
      subtitle={@report["assessment"]["decision"]}
      flash={assigns[:flash]}
    >
      <:actions>
            <.button href={"/applications/#{@instance.id}"} size="sm">Overview</.button>
            <.button href={"/application-operations/#{@instance.id}/assessment.report?run_id=#{@report["run"]["id"]}&download=1"} size="sm">Download report</.button>
            <a
              href={"/applications/#{@instance.id}/settings"}
              class="grid size-8 place-items-center text-text-muted transition-colors hover:text-text"
              aria-label="Instance settings"
            >
              <.icon name="hero-cog-6-tooth" class="size-4" />
            </a>
      </:actions>

      <.panel title="Run provenance" icon="hero-finger-print">
        <div class="flex flex-wrap gap-x-8 gap-y-2 text-sm text-text-muted">
          <span><strong class="text-base-content">Run:</strong> {@report["run"]["status"]}</span>
          <span><strong class="text-base-content">Collected:</strong> {format_datetime(@report["snapshot"] && @report["snapshot"]["collected_at"])}</span>
          <span><strong class="text-base-content">Completed:</strong> {format_datetime(@report["run"]["completed_at"])}</span>
          <span><strong class="text-base-content">Rule set:</strong> {@report["run"]["rule_set_version"]}</span>
        </div>
      </.panel>

      <section class="mt-10" aria-labelledby="decision-scope-heading">
        <h2 id="decision-scope-heading" class="text-2xl font-semibold">Decision and scope</h2>
        <div class="mt-4 grid gap-4 lg:grid-cols-2">
          <div class="rounded-xl border border-base-300 p-5">
            <h3 class="font-semibold">Decision supported</h3>
            <p class="mt-2 text-sm text-base-content/70">{@report["assessment"]["decision"]}</p>
          </div>
          <dl class="rounded-xl border border-base-300 p-5">
            <div :for={{key, value} <- scope_entries(@report)} class="grid grid-cols-[0.8fr_1.2fr] gap-3 border-b border-base-200 py-2 last:border-0">
              <dt class="text-sm font-medium">{humanize(key)}</dt>
              <dd class="break-words text-sm text-base-content/70">{display_value(value)}</dd>
            </div>
            <p :if={scope_entries(@report) == []} class="text-sm text-base-content/60">No scope metadata was declared.</p>
          </dl>
        </div>
      </section>

      <section class="mt-10" aria-labelledby="summary-heading">
        <h2 id="summary-heading" class="text-2xl font-semibold">Assessment summary</h2>
        <div class="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <.metric label="Inventory items" value={@report["summary"]["inventory_total"]} />
          <.metric label="Findings" value={@report["summary"]["finding_total"]} />
          <.metric label="Evidence items" value={@report["summary"]["evidence_total"]} />
          <.metric label="Relationships" value={@report["summary"]["relationship_total"]} />
        </div>
        <div class="mt-4 grid gap-4 lg:grid-cols-2">
          <div class="rounded-xl border border-base-300 p-5">
            <h3 class="font-semibold">Findings by severity</h3>
            <div class="mt-3 flex flex-wrap gap-2">
              <span :for={{severity, count} <- sorted_counts(@report["summary"]["findings_by_severity"])} class="rounded-full bg-base-200 px-3 py-1 text-sm">
                {humanize(severity)}: <strong>{count}</strong>
              </span>
              <span :if={@report["summary"]["finding_total"] == 0} class="text-sm text-base-content/60">No findings were produced by this Run.</span>
            </div>
          </div>
          <div class="rounded-xl border border-base-300 p-5">
            <h3 class="font-semibold">Collection limitations</h3>
            <ul :if={limitations(@report) != []} class="mt-3 list-disc space-y-2 pl-5 text-sm text-base-content/70">
              <li :for={limitation <- limitations(@report)}>{limitation}</li>
            </ul>
            <p :if={limitations(@report) == []} class="mt-3 text-sm text-base-content/60">
              The source snapshot declared no collection limitations. This does not imply that the assessment scope is complete.
            </p>
          </div>
        </div>
      </section>

      <section :if={@report["comparison"]} class="mt-10" aria-labelledby="change-heading">
        <h2 id="change-heading" class="text-2xl font-semibold">Change since previous snapshot</h2>
        <p class="mt-2 text-sm text-base-content/60">Compared with Run {@report["comparison"]["previous_run_id"]}.</p>
        <div class="mt-4 grid grid-cols-3 gap-3">
          <.metric label="Added" value={@report["comparison"]["summary"]["added"]} />
          <.metric label="Changed" value={@report["comparison"]["summary"]["changed"]} />
          <.metric label="Removed" value={@report["comparison"]["summary"]["removed"]} />
        </div>
      </section>

      <section class="mt-10" aria-labelledby="inventory-heading">
        <h2 id="inventory-heading" class="text-2xl font-semibold">Estate inventory</h2>
        <p class="mt-2 text-sm text-base-content/60">Items normalized from the approved evidence package. Expand a category to inspect its contents and provenance.</p>
        <div class="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div :for={{kind, items} <- inventory_groups(@report)} class="rounded-xl border border-base-300 p-4">
            <strong class="text-2xl">{length(items)}</strong><span class="mt-1 block text-xs uppercase">{humanize(kind)}</span>
          </div>
        </div>
        <div class="mt-6 space-y-3">
          <details :for={{kind, items} <- inventory_groups(@report)} class="rounded-xl border border-base-300 p-4">
            <summary class="cursor-pointer font-semibold">{humanize(kind)} ({length(items)})</summary>
            <div class="mt-4 overflow-x-auto">
              <table class="w-full text-left text-sm">
                <thead class="border-b border-base-300 text-xs uppercase text-base-content/50">
                  <tr><th class="px-2 py-2">Name</th><th class="px-2 py-2">Identifier</th><th class="px-2 py-2">Evidence</th></tr>
                </thead>
                <tbody>
                  <tr :for={item <- items} class="border-b border-base-200 align-top last:border-0">
                    <td class="px-2 py-2 font-medium">{item["name"]}</td>
                    <td class="break-all px-2 py-2 font-mono text-xs">{item["external_key"]}</td>
                    <td class="break-all px-2 py-2 text-xs text-base-content/60">{evidence_path(@report, item["evidence_item_id"])}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </details>
        </div>
      </section>

      <section class="mt-10" aria-labelledby="findings-heading">
        <h2 id="findings-heading" class="text-2xl font-semibold">Findings register</h2>
        <p class="mt-2 text-sm text-base-content/60">Deterministic findings identify their rule; expert observations identify their author and remain distinct from source facts.</p>
        <article :for={finding <- @report["findings"]} class="mt-4 rounded-xl border border-base-300 p-5">
          <p class="text-xs uppercase text-base-content/50">{finding["origin"]} · {finding["severity"]} · {finding["confidence"]} confidence · {finding["status"]}</p>
          <h3 class="mt-1 text-lg font-semibold">{finding["summary"]}</h3>
          <p class="mt-3 text-sm text-base-content/70">{finding["explanation"]}</p>
          <dl class="mt-4 grid gap-3 text-sm sm:grid-cols-2">
            <div><dt class="font-semibold">Recommendation</dt><dd class="mt-1 text-base-content/70">{finding["recommendation"]}</dd></div>
            <div>
              <dt class="font-semibold">Provenance</dt>
              <dd class="mt-1 break-words text-base-content/70">
                {finding_origin(finding)}<br />
                Evidence: {evidence_path(@report, finding["evidence_item_id"])}<br />
                Affected item: {inventory_name(@report, finding["inventory_item_id"])}
              </dd>
            </div>
          </dl>
        </article>
        <p :if={@report["findings"] == []} class="mt-4 rounded-xl bg-base-200 p-5 text-sm text-base-content/60">No findings were produced by this Run.</p>
      </section>

      <section :if={@report["review_decisions"] != []} class="mt-10" aria-labelledby="review-heading">
        <h2 id="review-heading" class="text-2xl font-semibold">Review history</h2>
        <div class="mt-4 overflow-x-auto rounded-xl border border-base-300 p-4">
          <table class="w-full text-left text-sm">
            <thead class="border-b border-base-300 text-xs uppercase text-base-content/50">
              <tr><th class="px-2 py-2">Finding</th><th class="px-2 py-2">Decision</th><th class="px-2 py-2">Rationale</th><th class="px-2 py-2">Recorded</th></tr>
            </thead>
            <tbody>
              <tr :for={decision <- @report["review_decisions"]} class="border-b border-base-200 last:border-0">
                <td class="px-2 py-2">{finding_name(@report, decision["finding_id"])}</td>
                <td class="px-2 py-2">{decision["from_status"]} → {decision["to_status"]}</td>
                <td class="px-2 py-2">{decision["rationale"]}</td>
                <td class="px-2 py-2">{format_datetime(decision["created_at"])}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="mt-10" aria-labelledby="method-heading">
        <h2 id="method-heading" class="text-2xl font-semibold">Method and provenance</h2>
        <div class="mt-4 grid gap-4 rounded-xl border border-base-300 p-5 text-sm sm:grid-cols-2">
          <div><strong>Target</strong><p class="mt-1 text-base-content/70">{@report["snapshot"] && @report["snapshot"]["target_key"]}</p></div>
          <div><strong>Source Adapter</strong><p class="mt-1 text-base-content/70">{@report["run"]["adapter"]["id"]} v{@report["run"]["adapter"]["version"]}</p></div>
          <div><strong>Deterministic rule set</strong><p class="mt-1 text-base-content/70">Version {@report["run"]["rule_set_version"]}</p></div>
          <div><strong>Report schema</strong><p class="mt-1 text-base-content/70">{@report["schema"]}</p></div>
        </div>
      </section>

      <section class="mt-10" aria-labelledby="evidence-heading">
        <h2 id="evidence-heading" class="text-2xl font-semibold">Evidence appendix</h2>
        <div :for={evidence <- @report["evidence"]} class="mt-3 rounded-lg bg-base-200 p-3 text-xs">
          <p class="font-semibold">{evidence["path"]}</p>
          <p class="mt-1 break-all font-mono text-base-content/60">SHA-256 {evidence["sha256"]} · {evidence["byte_size"]} bytes · {evidence["media_type"]}</p>
        </div>
      </section>
    </.application_frame>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)

  defp metric(assigns) do
    ~H"""
    <div class="rounded-xl border border-base-300 p-4">
      <strong class="text-2xl">{@value || 0}</strong><span class="mt-1 block text-xs uppercase">{@label}</span>
    </div>
    """
  end

  defp inventory_groups(report) do
    report["inventory"]
    |> Enum.group_by(& &1["kind"])
    |> Enum.sort_by(fn {kind, _items} -> kind end)
  end

  defp scope_entries(report) do
    report["assessment"]["scope"]
    |> Kernel.||(%{})
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
  end

  defp sorted_counts(counts), do: Enum.sort_by(counts || %{}, fn {key, _value} -> key end)

  defp limitations(%{"snapshot" => %{"limitations" => limitations}}), do: limitations || []
  defp limitations(_report), do: []

  defp evidence_path(_report, nil), do: "Not linked"

  defp evidence_path(report, evidence_id) do
    Enum.find_value(report["evidence"], "Evidence item not available", fn evidence ->
      if evidence["id"] == evidence_id, do: evidence["path"]
    end)
  end

  defp inventory_name(_report, nil), do: "Assessment-wide"

  defp inventory_name(report, inventory_id) do
    Enum.find_value(report["inventory"], "Inventory item not available", fn item ->
      if item["id"] == inventory_id, do: item["name"]
    end)
  end

  defp finding_name(report, finding_id) do
    Enum.find_value(report["findings"], finding_id, fn finding ->
      if finding["id"] == finding_id, do: finding["summary"]
    end)
  end

  defp finding_origin(%{"rule" => %{"id" => id, "version" => version}}),
    do: "Rule #{id} v#{version}"

  defp finding_origin(%{"origin" => "expert", "created_by_user_id" => user_id}),
    do: "Expert observation by #{user_id}"

  defp finding_origin(_finding), do: "Origin not available"

  defp humanize(value),
    do: value |> to_string() |> String.replace("_", " ") |> String.capitalize()

  defp display_value(nil), do: "Not declared"
  defp display_value(value) when is_binary(value), do: value
  defp display_value(value) when is_boolean(value) or is_number(value), do: to_string(value)
  defp display_value(value), do: Jason.encode!(value)

  defp format_datetime(nil), do: "Not recorded"

  defp format_datetime(%{year: _year} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_datetime(value), do: to_string(value)
end
