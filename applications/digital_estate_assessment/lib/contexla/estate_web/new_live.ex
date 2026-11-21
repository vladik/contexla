defmodule Contexla.EstateWeb.NewLive do
  use ContexlaUI, :live_view

  alias Contexla.ApplicationSDK.Runtime

  @impl true
  def mount(_params, %{"actor_id" => actor_id, "application_id" => application_id}, socket) do
    {:ok,
     socket
     |> assign(:actor_id, actor_id)
     |> assign(:application_id, application_id)
     |> assign(
       :form,
       to_form(%{"icon" => "", "name" => "", "description" => "", "decision" => ""},
         as: :assessment
       )
     )}
  end

  @impl true
  def handle_event("validate", %{"assessment" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :assessment))}
  end

  def handle_event("create", %{"assessment" => params}, socket) do
    attrs = %{
      "application_id" => socket.assigns.application_id,
      "icon" => params["icon"],
      "name" => params["name"],
      "description" => params["description"],
      "config" => %{
        "decision" => params["decision"],
        "scope" => %{"cms" => "drupal"}
      }
    }

    case Runtime.call(:platform, :create_instance, [socket.assigns.actor_id, attrs]) do
      {:ok, instance} ->
        {:noreply, redirect(socket, to: "/applications/#{instance.id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not create assessment: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.surface flash={assigns[:flash]}>
      <:header>
        <.header id="new-assessment-page-header" icon="hero-clipboard-document-check">
          Create an assessment
          <:subtitle>Define the estate and decision this evidence must support.</:subtitle>
          <:actions><.button href="/" size="sm">Back</.button></:actions>
        </.header>
      </:header>

      <.panel title="Assessment details" description="Name the estate and record the decision the assessment must inform." icon="hero-document-text">
        <.form
          for={@form}
          id="new-assessment"
          phx-change="validate"
          phx-submit="create"
          class="block"
        >
          <.form_layout>
            <.form_section
              title="Instance identity"
              description="Choose how this assessment appears in Contexla navigation."
            >
              <.icon_picker
                id="assessment-icon"
                name={@form[:icon].name}
                value={@form[:icon].value}
                default_icon="hero-clipboard-document-check"
              />
              <.input field={@form[:name]} label="Assessment name" required placeholder="e.g., College Drupal Estate" />
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="A short description of this assessment Instance"
                rows="2"
              />
            </.form_section>
            <.form_section
              title="Assessment purpose"
              description="Record the business or modernization decision this evidence must support."
            >
              <.input field={@form[:decision]} type="textarea" label="Decision to support" required placeholder="What decision should this evidence support?" rows="4" />
            </.form_section>
            <:actions>
              <.button type="submit" variant="primary">Create assessment</.button>
            </:actions>
          </.form_layout>
        </.form>
      </.panel>
    </.surface>
    """
  end
end
