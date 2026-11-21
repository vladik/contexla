defmodule ContexlaWeb.ApplicationOperationController do
  use ContexlaWeb, :controller

  alias Contexla.ApplicationSDK.Error
  alias Contexla.ApplicationOperations

  @reserved ~w(instance_id operation_id approval _csrf_token)

  def execute(conn, %{"instance_id" => instance_id, "operation_id" => operation_id} = params) do
    invoke(conn, instance_id, operation_id, params,
      transport: :command,
      approved: params["approval"] == "approved"
    )
  end

  def read(conn, %{"instance_id" => instance_id, "operation_id" => operation_id} = params) do
    invoke(conn, instance_id, operation_id, params, transport: :read)
  end

  defp invoke(conn, instance_id, operation_id, params, options) do
    input = Map.drop(params, @reserved)

    conn.assigns.current_scope
    |> ApplicationOperations.invoke(instance_id, operation_id, input, options)
    |> respond(conn)
  end

  defp respond({:ok, result, invocation}, conn) do
    json(conn, %{data: result, invocation_id: invocation.id})
  end

  defp respond({:download, contents, options, invocation}, conn) do
    conn
    |> put_resp_header("x-contexla-invocation-id", invocation.id)
    |> send_download({:binary, contents}, options)
  end

  defp respond({:error, reason, invocation}, conn) do
    error(conn, :unprocessable_entity, reason, invocation.id)
  end

  defp respond({:error, :operation_not_declared}, conn),
    do: error(conn, :not_found, :operation_not_declared)

  defp respond({:error, :instance_not_found}, conn),
    do: error(conn, :not_found, :instance_not_found)

  defp respond({:error, :operation_requires_post}, conn),
    do: error(conn, :method_not_allowed, :operation_requires_post)

  defp respond({:error, {:approval_required, _operation_id} = reason}, conn),
    do: error(conn, :conflict, reason)

  defp respond({:error, reason}, conn),
    do: error(conn, :unprocessable_entity, reason)

  defp error(conn, status, reason, invocation_id \\ nil) do
    code = Error.code(reason)

    json(conn |> put_status(status), %{
      error: %{
        code: code,
        message: error_message(code),
        invocation_id: invocation_id
      }
    })
  end

  defp error_message("operation_not_declared"),
    do: "The Application does not declare this Operation."

  defp error_message("instance_not_found"), do: "The Application Instance was not found."

  defp error_message("operation_requires_post"),
    do: "This Operation must be submitted as a command."

  defp error_message("approval_required"), do: "This Operation requires explicit approval."

  defp error_message("required_capability_unavailable"),
    do: "A required Capability is unavailable."

  defp error_message("application_version_mismatch"),
    do: "The Application Instance version is unavailable."

  defp error_message(_code), do: "The Operation could not be completed."
end
