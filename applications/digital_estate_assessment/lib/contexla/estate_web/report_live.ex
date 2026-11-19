defmodule Contexla.EstateWeb.ReportLive do
  use Phoenix.LiveView
  import Phoenix.Component

  alias Contexla.ApplicationSDK.Instance
  alias Contexla.Estate.Assessments

  @impl true
  def mount(
        _params,
        %{"instance" => data, "surface_params" => %{"run_id" => run_id}},
        socket
      ) do
    instance = struct!(Instance, atomize(data))
    {:ok, assign(socket, instance: instance, report: Assessments.report(instance, run_id))}
  end

  def mount(_params, %{"instance" => data}, socket) do
    instance = struct!(Instance, atomize(data))

    {:ok,
     socket
     |> put_flash(:error, "Choose a completed Run before opening its report.")
     |> redirect(to: "/applications/#{instance.id}/overview")}
  end

  defp atomize(data),
    do: Map.new(data, fn {key, value} -> {String.to_existing_atom(key), value} end)

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-5xl px-4 py-10 sm:px-6">
      <a href={"/applications/#{@instance.id}/overview"} class="text-sm font-medium text-indigo-600">← Assessment</a>
      <p class="mt-8 text-sm font-semibold uppercase tracking-[0.18em] text-indigo-600">Contexla Digital Estate Assessment</p>
      <h1 class="mt-2 text-4xl font-semibold tracking-tight">{@report["assessment"]["name"]}</h1>
      <p class="mt-3 text-lg text-base-content/60">{@report["assessment"]["decision"]}</p>
      <a href={"/application-operations/#{@instance.id}/assessment.report?run_id=#{@report["run"]["id"]}&download=1"} class="mt-5 inline-flex rounded-lg border border-base-300 px-4 py-2 text-sm font-semibold">Download JSON</a>

      <section class="mt-10">
        <h2 class="text-2xl font-semibold">Inventory</h2>
        <div class="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div :for={{kind, items} <- Enum.group_by(@report["inventory"], & &1["kind"])} class="rounded-xl border border-base-300 p-4">
            <strong class="text-2xl">{length(items)}</strong><span class="mt-1 block text-xs uppercase">{String.replace(kind, "_", " ")}</span>
          </div>
        </div>
      </section>

      <section class="mt-10">
        <h2 class="text-2xl font-semibold">Findings</h2>
        <article :for={finding <- @report["findings"]} class="mt-4 rounded-xl border border-base-300 p-5">
          <p class="text-xs uppercase text-base-content/50">{finding["origin"]} · {finding["severity"]} · {finding["status"]}</p>
          <h3 class="mt-1 text-lg font-semibold">{finding["summary"]}</h3>
          <p class="mt-3 text-sm text-base-content/70">{finding["explanation"]}</p>
          <p class="mt-3 text-sm"><strong>Recommendation:</strong> {finding["recommendation"]}</p>
        </article>
      </section>

      <section class="mt-10">
        <h2 class="text-2xl font-semibold">Evidence appendix</h2>
        <div :for={evidence <- @report["evidence"]} class="mt-3 rounded-lg bg-base-200 p-3 font-mono text-xs">
          {evidence["path"]} · {evidence["sha256"]}
        </div>
      </section>
    </main>
    """
  end
end
