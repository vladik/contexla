defmodule Contexla.Applications.Sdk.Manifest do
  @moduledoc """
  Reads contexla-application.json at compile time and derives the Application
  definition. Use this in your Package module to eliminate duplication between
  the manifest and compiled code.

      defmodule MyApp.Package do
        @behaviour Contexla.Applications.Sdk.Application
        use Contexla.Applications.Sdk.Manifest

        @impl true
        def validate_instance_config(config), do: ...

        @impl true
        def execute_operation(op, instance, input), do: ...
      end

  The manifest must be at `contexla-application.json` relative to the project
  root (one level above the `lib/` directory containing this module).
  """

  alias Contexla.Applications.Sdk.{Definition, Operation, Queue, Surface}
  alias Contexla.Applications.Sdk.Requirement

  defmacro __using__(_opts) do
    manifest_path =
      __CALLER__.file
      |> Path.expand()
      |> Path.dirname()
      |> Path.join("../contexla-application.json")
      |> Path.expand()

    manifest =
      manifest_path
      |> File.read!()
      |> Jason.decode!()

    escaped = Macro.escape(manifest)

    quote do
      @external_resource unquote(manifest_path)

      @impl true
      def definition do
        Contexla.Applications.Sdk.Manifest.to_definition(unquote(escaped), __MODULE__)
      end

      @impl true
      def available_operations do
        Contexla.Applications.Sdk.Manifest.to_operations(unquote(escaped))
      end

      @impl true
      def required_adapter_contracts do
        Map.get(unquote(escaped), "requiredAdapterContracts", [])
      end
    end
  end

  @doc "Converts a decoded manifest map to a Definition struct."
  @spec to_definition(map(), module()) :: Definition.t()
  def to_definition(manifest, entry_module) do
    %Definition{
      id: manifest["applicationId"],
      name: manifest["name"],
      icon: manifest["icon"],
      version: manifest["version"],
      otp_application: String.to_atom(manifest["otpApplication"]),
      entry_module: entry_module,
      description: Map.get(manifest, "description", ""),
      database_schema: Map.get(manifest, "databaseSchema"),
      config_schema: Map.get(manifest, "configSchema", %{}),
      queues: to_queues(manifest),
      operations: to_operations(manifest),
      surfaces: to_surfaces(manifest),
      required_adapter_contracts: Map.get(manifest, "requiredAdapterContracts", [])
    }
  end

  @doc "Converts the manifest operations array to Operation structs."
  @spec to_operations(map()) :: [Operation.t()]
  def to_operations(manifest) do
    manifest
    |> Map.get("operations", [])
    |> Enum.map(&to_operation/1)
  end

  defp to_operation(op) when is_map(op) do
    %Operation{
      id: op["id"],
      name: Map.get(op, "name", op["id"]),
      description: Map.get(op, "description", ""),
      kind: parse_kind(Map.get(op, "kind", "command")),
      queue: op |> Map.get("queue", "default") |> String.to_atom(),
      max_attempts: Map.get(op, "maxAttempts", 3),
      timeout_seconds: Map.get(op, "timeoutSeconds", 60),
      requires_approval: Map.get(op, "requiresApproval", false),
      input_schema: Map.get(op, "inputSchema", %{"type" => "object", "properties" => %{}}),
      required_tools: op |> Map.get("requiredTools", []) |> Enum.map(&to_requirement/1)
    }
  end

  defp to_queues(manifest) do
    manifest
    |> Map.get("queues", [%{"name" => "default", "concurrency" => 10}])
    |> Enum.map(fn q ->
      %Queue{
        name: q["name"] |> String.to_atom(),
        concurrency: q["concurrency"]
      }
    end)
  end

  defp to_surfaces(manifest) do
    manifest
    |> Map.get("surfaces", [])
    |> Enum.map(fn s ->
      %Surface{
        id: s["id"] |> String.to_atom(),
        path: s["path"],
        module: Module.concat([s["module"]]),
        role: s["role"] |> String.to_atom(),
        label: Map.get(s, "label"),
        default: Map.get(s, "default", false),
        kind: s |> Map.get("kind", "page") |> String.to_atom()
      }
    end)
  end

  defp to_requirement(r) do
    %Requirement{tool_id: r["toolId"], version: r["version"]}
  end

  defp parse_kind("read"), do: :read
  defp parse_kind(_), do: :command
end
