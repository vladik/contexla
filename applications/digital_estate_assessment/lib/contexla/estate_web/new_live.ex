defmodule Contexla.EstateWeb.NewLive do
  use Phoenix.LiveView
  import Phoenix.Component

  alias Contexla.ApplicationSDK.Runtime

  @impl true
  def mount(_params, %{"actor_id" => actor_id, "application_id" => application_id}, socket) do
    {:ok,
     socket
     |> assign(:actor_id, actor_id)
     |> assign(:application_id, application_id)
     |> assign(:form, to_form(%{"name" => "", "decision" => ""}, as: :assessment))}
  end

  @impl true
  def handle_event("create", %{"assessment" => params}, socket) do
    attrs = %{
      "application_id" => socket.assigns.application_id,
      "name" => params["name"],
      "config" => %{
        "decision" => params["decision"],
        "scope" => %{"cms" => "drupal"}
      }
    }

    case Runtime.call(:platform, :create_instance, [socket.assigns.actor_id, attrs]) do
      {:ok, instance} ->
        {:noreply, push_navigate(socket, to: "/applications/#{instance.id}/overview")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not create assessment: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-3xl px-4 py-10 sm:px-6">
      <a href="/" class="text-sm font-medium text-indigo-600">← Applications</a>
      <p class="mt-8 text-sm font-semibold uppercase tracking-[0.18em] text-indigo-600">Digital Estate Assessment</p>
      <h1 class="mt-2 text-3xl font-semibold tracking-tight">Create an assessment</h1>
      <p class="mt-3 text-base-content/60">Define the estate and decision this evidence must support.</p>

      <.form for={@form} id="new-assessment" phx-submit="create" class="mt-8 space-y-5 rounded-2xl border border-base-300 p-6">
        <label class="block">
          <span class="text-sm font-medium">Assessment name</span>
          <input name={@form[:name].name} value={@form[:name].value} required class="mt-2 w-full rounded-xl border border-base-300 bg-base-100 px-4 py-3" />
        </label>
        <label class="block">
          <span class="text-sm font-medium">Decision to support</span>
          <textarea name={@form[:decision].name} required class="mt-2 min-h-28 w-full rounded-xl border border-base-300 bg-base-100 px-4 py-3">{@form[:decision].value}</textarea>
        </label>
        <button class="rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white hover:bg-indigo-500">Create assessment</button>
      </.form>
    </main>
    """
  end
end
