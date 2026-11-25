defmodule Contexla.Platform.ToolRuntime.Registry do
  @moduledoc "In-memory registry of trusted, code-authoritative bundled Tools."

  use GenServer

  alias Contexla.Tools.Sdk.Catalog, as: ToolSDK

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def tools, do: GenServer.call(__MODULE__, :tools)
  def fetch_tool(id, version), do: GenServer.call(__MODULE__, {:tool, id, version})

  @impl true
  def init(_opts) do
    case load_tools() do
      {:ok, tools} -> {:ok, %{tools: tools}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call(:tools, _from, state) do
    {:reply, state.tools |> Map.values() |> Enum.sort_by(&{&1.name, &1.version}), state}
  end

  def handle_call({:tool, id, version}, _from, state) do
    {:reply, Map.fetch(state.tools, {id, version}), state}
  end

  defp load_tools do
    :contexla
    |> Application.get_env(:tool_packages, [])
    |> Enum.reduce_while({:ok, %{}}, fn package, {:ok, loaded} ->
      case ToolSDK.validate_package(package) do
        {:ok, tools} -> add_tools(loaded, tools, package)
        {:error, reason} -> {:halt, {:error, {:invalid_package, package, reason}}}
      end
    end)
  end

  defp add_tools(loaded, tools, package) do
    Enum.reduce_while(tools, {:ok, loaded}, fn tool, {:ok, current} ->
      key = {tool.id, tool.version}

      if Map.has_key?(current, key) do
        {:halt, {:error, {:duplicate_tool_identity, key}}}
      else
        {:cont, {:ok, Map.put(current, key, tool)}}
      end
    end)
    |> case do
      {:ok, updated} -> {:cont, {:ok, updated}}
      {:error, reason} -> {:halt, {:error, {:invalid_package, package, reason}}}
    end
  end
end
