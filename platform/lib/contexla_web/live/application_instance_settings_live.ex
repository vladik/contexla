defmodule ContexlaWeb.ApplicationInstanceSettingsLive do
  use ContexlaWeb, :live_view

  alias Contexla.Applications
  alias Contexla.Packages.Registry

  @impl true
  def mount(%{"instance_id" => instance_id}, _session, socket) do
    scope = socket.assigns.current_scope
    instance = Applications.get_instance!(scope, instance_id)
    {:ok, definition} = Registry.fetch_application(instance.application_id)
    {:ok, settings_surface} = Registry.fetch_settings_surface(instance.application_id)
    {:ok, changeset} = Applications.change_instance_settings(scope, instance.id)

    {:ok,
     socket
     |> assign(:page_title, "#{instance.name} Settings")
     |> assign(:instance, instance)
     |> assign(:definition, definition)
     |> assign(:application_settings_path, settings_surface.path)
     |> assign(:form, to_form(changeset, as: :instance))}
  end

  @impl true
  def handle_event("validate", %{"instance" => attrs}, socket) do
    {:ok, changeset} =
      Applications.change_instance_settings(
        socket.assigns.current_scope,
        socket.assigns.instance.id,
        attrs
      )

    {:noreply, assign(socket, :form, to_form(%{changeset | action: :validate}, as: :instance))}
  end

  def handle_event("save", %{"instance" => attrs}, socket) do
    case Applications.update_instance_settings(
           socket.assigns.current_scope,
           socket.assigns.instance.id,
           attrs
         ) do
      {:ok, instance} ->
        {:noreply,
         socket
         |> put_flash(:success, "Instance settings updated.")
         |> redirect(to: "/applications/#{instance.id}/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :instance))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.application_frame
        id="instance-settings-header"
        icon="hero-cog-6-tooth"
        title="Instance settings"
        subtitle={@instance.name}
      >
        <:navigation>
          <.tabs id="instance-settings-tabs" label="Instance settings sections">
            <:tab
              label="General"
              icon="hero-adjustments-horizontal"
              navigate={"/applications/#{@instance.id}/settings"}
              selected
            />
            <:tab
              label="Application"
              icon={@definition.icon}
              navigate={"/applications/#{@instance.id}/#{@application_settings_path}"}
            />
          </.tabs>
        </:navigation>

        <.panel
          title="General"
          description="Control how this Instance appears in platform navigation."
          icon="hero-identification"
        >
          <.form
            for={@form}
            id="instance-settings-form"
            phx-change="validate"
            phx-submit="save"
            class="block"
          >
            <.form_layout>
              <.form_section
                title="Instance identity"
                description="Choose the icon, name, and description used throughout Contexla."
              >
                <.icon_picker
                  id="instance-icon"
                  name={@form[:icon].name}
                  value={@form[:icon].value}
                  default_icon={@definition.icon}
                />
                <.input field={@form[:name]} label="Instance name" required />
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  placeholder="A short description of this Application Instance"
                  rows="2"
                />
              </.form_section>
              <:actions>
                <UIButton.button type="submit" variant="primary">Save settings</UIButton.button>
              </:actions>
            </.form_layout>
          </.form>
        </.panel>
      </.application_frame>
    </Layouts.app>
    """
  end
end
