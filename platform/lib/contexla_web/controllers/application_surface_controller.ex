defmodule ContexlaWeb.ApplicationSurfaceController do
  use ContexlaWeb, :controller

  alias Contexla.Applications
  alias Contexla.Packages.Registry

  def new(conn, %{"application_id" => application_id, "surface" => path} = params) do
    with {:ok, surface} <- Registry.fetch_surface(application_id, path, :new) do
      Phoenix.LiveView.Controller.live_render(conn, surface.module,
        session: %{
          "actor_id" => conn.assigns.current_scope.user.id,
          "application_id" => application_id,
          "surface_params" => surface_params(params)
        }
      )
    else
      _ -> send_resp(conn, :not_found, "Application surface not found")
    end
  end

  def show(conn, %{"instance_id" => instance_id, "surface" => path} = params) do
    scope = conn.assigns.current_scope

    with {:ok, instance} <- Applications.fetch_instance(scope, instance_id),
         {:ok, surface} <- Registry.fetch_surface(instance.application_id, path, :instance) do
      Phoenix.LiveView.Controller.live_render(conn, surface.module,
        session: %{
          "instance" => instance_session(instance, scope.user.id),
          "surface_params" => surface_params(params)
        }
      )
    else
      _ -> send_resp(conn, :not_found, "Application surface not found")
    end
  end

  def show_default(conn, %{"instance_id" => instance_id} = params) do
    scope = conn.assigns.current_scope

    with {:ok, instance} <- Applications.fetch_instance(scope, instance_id),
         {:ok, surface} <- Registry.fetch_default_surface(instance.application_id) do
      render_instance_surface(conn, surface, instance, scope.user.id, params)
    else
      _ -> send_resp(conn, :not_found, "Application surface not found")
    end
  end

  defp render_instance_surface(conn, surface, instance, actor_id, params) do
    Phoenix.LiveView.Controller.live_render(conn, surface.module,
      session: %{
        "instance" => instance_session(instance, actor_id),
        "surface_params" => surface_params(params)
      }
    )
  end

  defp surface_params(params) do
    Map.drop(params, ["application_id", "instance_id", "surface"])
  end

  defp instance_session(instance, actor_id) do
    %{
      "id" => instance.id,
      "application_id" => instance.application_id,
      "application_version" => instance.application_version,
      "name" => instance.name,
      "description" => instance.description,
      "status" => to_string(instance.status),
      "config" => instance.config,
      "actor_id" => actor_id
    }
  end
end
