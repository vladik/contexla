defmodule Contexla.Platform.Web.AgentActivityController do
  use Contexla.Platform.Web, :controller

  alias Contexla.Platform.ApplicationOperations
  alias Contexla.Platform.Packages.Registry

  def index(conn, params) do
    scope = conn.assigns.current_scope
    instance_id = params["instance_id"]
    invocations = ApplicationOperations.list_recent_invocations(scope, instance_id: instance_id)
    names = operation_name_map()

    items =
      Enum.map(invocations, fn inv ->
        %{
          id: inv.id,
          operation_id: inv.operation_id,
          operation_name: Map.get(names, inv.operation_id, inv.operation_id),
          status: inv.status,
          started_at: DateTime.to_iso8601(inv.started_at),
          completed_at: inv.completed_at && DateTime.to_iso8601(inv.completed_at),
          duration_ms: duration_ms(inv.started_at, inv.completed_at),
          instance_name: inv.application_instance && inv.application_instance.name
        }
      end)

    json(conn, %{invocations: items})
  end

  defp operation_name_map do
    Registry.applications()
    |> Enum.flat_map(fn definition ->
      Enum.map(definition.operations, fn op -> {op.id, op.name} end)
    end)
    |> Map.new()
  rescue
    _ -> %{}
  end

  defp duration_ms(_started_at, nil), do: nil

  defp duration_ms(started_at, completed_at),
    do: DateTime.diff(completed_at, started_at, :millisecond)
end
