defmodule Contexla.Platform.Web.McpController do
  @moduledoc """
  MCP (Model Context Protocol) JSON-RPC 2.0 endpoint.

  Exposes Application Operations as discoverable tools for AI agents.
  Requires CONTEXLA_MCP_API_KEY environment variable to be set.

  Supported methods:
    tools/list  — returns all Operations as MCP tool definitions
    tools/call  — invokes an Operation through the platform boundary
  """

  use Contexla.Platform.Web, :controller

  import Ecto.Query, only: [from: 2]

  alias Contexla.Platform.{ApplicationOperations, Applications, Repo}
  alias Contexla.Platform.Accounts.{Scope, User}
  alias Contexla.Platform.Packages.Registry

  def handle(conn, params) do
    request_id = params["id"]

    with {:ok, scope} <- authenticate(conn),
         {:ok, method} <- validate_jsonrpc(params) do
      case dispatch(scope, method, params["params"] || %{}) do
        {:ok, result} ->
          json(conn, %{jsonrpc: "2.0", id: request_id, result: result})

        {:error, code, message} ->
          json(conn, %{
            jsonrpc: "2.0",
            id: request_id,
            error: %{code: code, message: message}
          })
      end
    else
      {:error, :disabled} ->
        conn
        |> put_status(404)
        |> json(%{error: "MCP is not configured on this installation"})

      {:error, :unauthenticated} ->
        conn
        |> put_status(401)
        |> json(%{
          jsonrpc: "2.0",
          id: request_id,
          error: %{code: -32_001, message: "Authentication required"}
        })

      {:error, :invalid_request} ->
        json(conn, %{
          jsonrpc: "2.0",
          id: request_id,
          error: %{code: -32_600, message: "Invalid Request"}
        })
    end
  end

  defp authenticate(conn) do
    configured_key = Application.get_env(:contexla, :mcp_api_key)

    if is_nil(configured_key) do
      {:error, :disabled}
    else
      with ["Bearer " <> key] <- get_req_header(conn, "authorization"),
           true <- Plug.Crypto.secure_compare(key, configured_key),
           user when not is_nil(user) <-
             Repo.one(from u in User, where: u.role == :admin, limit: 1) do
        {:ok, Scope.for_user(user)}
      else
        _ -> {:error, :unauthenticated}
      end
    end
  end

  defp validate_jsonrpc(%{"jsonrpc" => "2.0", "method" => method}) when is_binary(method),
    do: {:ok, method}

  defp validate_jsonrpc(_), do: {:error, :invalid_request}

  defp dispatch(_scope, "tools/list", _params) do
    tools = platform_tools() ++ application_tools()
    {:ok, %{tools: tools}}
  end

  defp dispatch(scope, "tools/call", %{"name" => "contexla.list_instances"}) do
    instances = Applications.list_navigation_instances(scope)

    text =
      if instances == [] do
        "No Application Instances configured."
      else
        Enum.map_join(instances, "\n", fn inst ->
          "id=#{inst.id}  name=#{inst.name}  application=#{inst.application_id}"
        end)
      end

    {:ok, %{content: [%{type: "text", text: text}], isError: false}}
  end

  defp dispatch(scope, "tools/call", %{"name" => op_id, "arguments" => args})
       when is_binary(op_id) do
    instance_id = Map.get(args, "instance_id")
    input = Map.drop(args, ["instance_id"])

    if is_nil(instance_id) do
      {:error, -32_602, "Missing required argument: instance_id"}
    else
      result =
        ApplicationOperations.invoke(scope, instance_id, op_id, input,
          transport: :command,
          approved: true
        )

      mcp_result_from_invocation(result)
    end
  end

  defp dispatch(_scope, "tools/call", _params) do
    {:error, -32_602, "Invalid params: name and arguments are required"}
  end

  defp dispatch(_scope, method, _params) do
    {:error, -32_601, "Method not found: #{method}"}
  end

  defp mcp_result_from_invocation({:ok, result, invocation}) do
    text = "Succeeded. invocation_id=#{invocation.id}\n#{Jason.encode!(result, pretty: true)}"
    {:ok, %{content: [%{type: "text", text: text}], isError: false}}
  end

  defp mcp_result_from_invocation({:download, _contents, _opts, invocation}) do
    text = "Download produced. invocation_id=#{invocation.id}"
    {:ok, %{content: [%{type: "text", text: text}], isError: false}}
  end

  defp mcp_result_from_invocation({:error, reason, invocation}) do
    text = "Failed: #{format_error(reason)}. invocation_id=#{invocation.id}"
    {:ok, %{content: [%{type: "text", text: text}], isError: true}}
  end

  defp mcp_result_from_invocation({:error, reason}) do
    {:error, -32_603, "Operation error: #{format_error(reason)}"}
  end

  defp format_error(:operation_not_declared), do: "operation not declared"
  defp format_error(:operation_not_executable), do: "operation not executable"
  defp format_error(:instance_not_found), do: "instance not found"
  defp format_error({:approval_required, _}), do: "approval required"
  defp format_error({:schema_validation_failed, _}), do: "input schema validation failed"
  defp format_error(reason) when is_atom(reason), do: to_string(reason)
  defp format_error(reason), do: inspect(reason)

  defp platform_tools do
    [
      %{
        name: "contexla.list_instances",
        description:
          "List all configured Application Instances with their IDs. " <>
            "Call this first to get instance_id values required by other operations.",
        inputSchema: %{
          "type" => "object",
          "properties" => %{},
          "required" => [],
          "additionalProperties" => false
        }
      }
    ]
  end

  defp application_tools do
    Registry.applications()
    |> Enum.flat_map(fn definition ->
      Enum.map(definition.operations, fn op ->
        %{
          name: op.id,
          description: "[#{definition.name}] #{op.description || op.name}",
          inputSchema: with_instance_id(op.input_schema)
        }
      end)
    end)
  rescue
    _ -> []
  end

  defp with_instance_id(schema) do
    id_prop = %{
      "instance_id" => %{
        "type" => "string",
        "description" => "Application Instance ID (from contexla.list_instances)"
      }
    }

    existing_props = Map.get(schema, "properties", %{})
    existing_required = Map.get(schema, "required", [])

    Map.merge(schema, %{
      "properties" => Map.merge(id_prop, existing_props),
      "required" => ["instance_id" | Enum.reject(existing_required, &(&1 == "instance_id"))]
    })
  end
end
