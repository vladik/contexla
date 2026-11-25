defmodule Contexla.Applications.DigitalEstateAssessment.Web.SettingsLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.{Instance, Runtime}

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)

    {:ok,
     socket
     |> assign(:instance, instance)
     |> assign(:form, settings_form(instance.config))}
  end

  @impl true
  def handle_event("validate", %{"settings" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :settings))}
  end

  def handle_event("save", %{"settings" => params}, socket) do
    scope =
      socket.assigns.instance.config
      |> Map.get("scope", %{})
      |> Map.merge(%{
        "cms" => params["cms"],
        "environment" => params["environment"]
      })

    config =
      socket.assigns.instance.config
      |> Map.put("decision", params["decision"])
      |> Map.put("scope", scope)

    case Runtime.update_instance_config(
           socket.assigns.instance.actor_id,
           socket.assigns.instance.id,
           config
         ) do
      {:ok, _instance} ->
        {:noreply,
         socket
         |> put_flash(:success, "Application settings updated.")
         |> redirect(to: "/applications/#{socket.assigns.instance.id}/configuration")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Application settings could not be updated.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.application_frame
      id="assessment-settings-header"
      icon="hero-cog-6-tooth"
      title="Application settings"
      subtitle={@instance.name}
      flash={assigns[:flash]}
    >

      <:navigation>
        <.tabs id="assessment-settings-tabs" label="Instance settings sections">
          <:tab
            label="General"
            icon="hero-adjustments-horizontal"
            navigate={"/applications/#{@instance.id}/settings"}
          />
          <:tab
            label="Application"
            icon="hero-clipboard-document-check"
            navigate={"/applications/#{@instance.id}/configuration"}
            selected
          />
        </.tabs>
      </:navigation>

      <.panel
          title="Assessment configuration"
          description="Update the decision and estate scope used by future Runs. Existing evidence and completed Runs remain unchanged."
          icon="hero-clipboard-document-check"
        >
          <.form
            for={@form}
            id="assessment-settings-form"
            phx-change="validate"
            phx-submit="save"
            class="block"
          >
            <.form_layout>
              <.form_section
                title="Assessment purpose"
                description="Define the decision that future assessment Runs must support."
              >
                <.input
                  field={@form[:decision]}
                  type="textarea"
                  label="Decision to support"
                  required
                  rows="4"
                />
              </.form_section>
              <.form_section
                title="Estate scope"
                description="Identify the source platform and environment represented by imported evidence."
              >
                <.input field={@form[:cms]} label="CMS" required />
                <.input field={@form[:environment]} label="Environment" />
              </.form_section>
              <:actions>
                <.button type="submit" variant="primary">Save settings</.button>
              </:actions>
            </.form_layout>
          </.form>
      </.panel>
    </.application_frame>
    """
  end

  defp settings_form(config) do
    scope = config["scope"] || %{}

    to_form(
      %{
        "decision" => config["decision"] || "",
        "cms" => scope["cms"] || "",
        "environment" => scope["environment"] || ""
      },
      as: :settings
    )
  end
end
