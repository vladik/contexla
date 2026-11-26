defmodule Contexla.Applications.ContentIntegrityMonitor.Web.NewLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.Runtime

  @impl true
  def mount(_params, %{"actor_id" => actor_id, "application_id" => application_id}, socket) do
    {:ok,
     socket
     |> assign(:actor_id, actor_id)
     |> assign(:application_id, application_id)
     |> assign(
       :form,
       to_form(
         %{
           "icon" => "",
           "name" => "",
           "description" => "",
           "purpose" =>
             "Monitor important facts across authoritative sources and delivered representations."
         },
         as: :instance
       )
     )}
  end

  @impl true
  def handle_event("validate", %{"instance" => params}, socket),
    do: {:noreply, assign(socket, :form, to_form(params, as: :instance))}

  def handle_event("create", %{"instance" => params}, socket) do
    attrs = %{
      "application_id" => socket.assigns.application_id,
      "icon" => params["icon"],
      "name" => params["name"],
      "description" => params["description"],
      "config" => %{
        "purpose" => params["purpose"]
      }
    }

    case Runtime.create_instance(socket.assigns.actor_id, attrs) do
      {:ok, instance} -> {:noreply, redirect(socket, to: "/applications/#{instance.id}")}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Could not create the Instance.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.surface flash={assigns[:flash]}>
      <:header>
        <.header id="new-instance-header" icon="hero-shield-check">
          Create Content Integrity Monitor Instance
          <:subtitle>Define its identity and initial purpose.</:subtitle>
        </.header>
      </:header>
      <.panel title="Instance details" description="Identity first, followed by domain configuration.">
        <.form for={@form} id="new-instance" phx-change="validate" phx-submit="create">
          <.form_layout>
            <.form_section title="Instance identity">
              <.icon_picker id="instance-icon" name={@form[:icon].name} value={@form[:icon].value} default_icon="hero-shield-check" />
              <.input field={@form[:name]} label="Name" required />
              <.input field={@form[:description]} type="textarea" label="Description" rows="2" />
            </.form_section>
            <.form_section title="Purpose" description="Describe the operational integrity outcome for this Instance.">
              <.input field={@form[:purpose]} type="textarea" label="Purpose" required rows="4" />
            </.form_section>
            <:actions><.button type="submit" variant="primary">Create Instance</.button></:actions>
          </.form_layout>
        </.form>
      </.panel>
    </.surface>
    """
  end
end
