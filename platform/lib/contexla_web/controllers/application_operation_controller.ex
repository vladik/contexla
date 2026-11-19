defmodule ContexlaWeb.ApplicationOperationController do
  use ContexlaWeb, :controller

  alias Contexla.ApplicationSDK.Instance, as: SDKInstance
  alias Contexla.Applications
  alias Contexla.Packages.Registry

  def execute(conn, %{"instance_id" => instance_id, "operation_id" => operation_id} = params) do
    scope = conn.assigns.current_scope

    with {:ok, instance} <- Applications.fetch_instance(scope, instance_id),
         {:ok, {entry, _definition}} <- Registry.fetch_application_entry(instance.application_id),
         true <- function_exported?(entry, :execute_operation, 3),
         context <- instance_context(instance, scope.user.id),
         {:ok, result} <-
           entry.execute_operation(
             operation_id,
             context,
             Map.drop(params, ["instance_id", "operation_id"])
           ) do
      json(conn, result)
    else
      {:download, contents, options} ->
        send_download(conn, {:binary, contents}, options)

      {:error, :not_found} ->
        send_resp(conn, :not_found, "Application operation not found")

      {:error, reason} ->
        json(conn |> put_status(:unprocessable_entity), %{error: inspect(reason)})

      false ->
        send_resp(conn, :not_implemented, "Application operation is not executable")
    end
  end

  defp instance_context(instance, actor_id) do
    %SDKInstance{
      id: instance.id,
      application_id: instance.application_id,
      application_version: instance.application_version,
      name: instance.name,
      status: instance.status,
      config: instance.config,
      actor_id: actor_id
    }
  end
end
