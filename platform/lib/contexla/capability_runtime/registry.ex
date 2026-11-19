defmodule Contexla.CapabilityRuntime.Registry do
  @moduledoc """
  In-memory registry of trusted Capability contracts and bundled Processors.

  Code definitions are authoritative for bundled packages. The PostgreSQL
  catalog mirrors these definitions for binding, querying, and invocation
  history.
  """

  use GenServer

  alias Contexla.CapabilitySDK

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def capabilities, do: GenServer.call(__MODULE__, :capabilities)
  def processors, do: GenServer.call(__MODULE__, :processors)
  def fetch_capability(id, version), do: GenServer.call(__MODULE__, {:capability, id, version})
  def fetch_processor(id, version), do: GenServer.call(__MODULE__, {:processor, id, version})

  @impl true
  def init(_opts) do
    with {:ok, capabilities} <- load_capabilities(),
         {:ok, processors} <- load_processors(),
         :ok <- validate_implementations(capabilities, processors),
         :ok <- validate_default_processors(processors) do
      {:ok, %{capabilities: capabilities, processors: processors}}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call(:capabilities, _from, state) do
    {:reply, state.capabilities |> Map.values() |> Enum.sort_by(&{&1.name, &1.contract_version}),
     state}
  end

  def handle_call(:processors, _from, state) do
    {:reply, state.processors |> Map.values() |> Enum.sort_by(&{&1.id, &1.version}), state}
  end

  def handle_call({:capability, id, version}, _from, state) do
    {:reply, Map.fetch(state.capabilities, {id, version}), state}
  end

  def handle_call({:processor, id, version}, _from, state) do
    {:reply, Map.fetch(state.processors, {id, version}), state}
  end

  defp load_capabilities do
    :contexla
    |> Application.get_env(:capability_packages, [])
    |> load_packages(&CapabilitySDK.validate_capability_package/1, &{&1.id, &1.contract_version})
  end

  defp load_processors do
    :contexla
    |> Application.get_env(:processor_packages, [])
    |> load_packages(&CapabilitySDK.validate_processor_package/1, &{&1.id, &1.version})
  end

  defp load_packages(packages, validator, identity) do
    Enum.reduce_while(packages, {:ok, %{}}, fn package, {:ok, loaded} ->
      case validator.(package) do
        {:ok, definitions} ->
          case add_definitions(loaded, definitions, identity) do
            {:ok, updated} -> {:cont, {:ok, updated}}
            {:error, reason} -> {:halt, {:error, {:invalid_package, package, reason}}}
          end

        {:error, reason} ->
          {:halt, {:error, {:invalid_package, package, reason}}}
      end
    end)
  end

  defp add_definitions(loaded, definitions, identity) do
    Enum.reduce_while(definitions, {:ok, loaded}, fn definition, {:ok, current} ->
      key = identity.(definition)

      if Map.has_key?(current, key) do
        {:halt, {:error, {:duplicate_identity, key}}}
      else
        {:cont, {:ok, Map.put(current, key, definition)}}
      end
    end)
  end

  defp validate_implementations(capabilities, processors) do
    Enum.reduce_while(processors, :ok, fn {_key, processor}, :ok ->
      capability_key = {processor.capability_id, processor.capability_contract_version}

      case Map.fetch(capabilities, capability_key) do
        :error ->
          {:halt, {:error, {:processor_capability_missing, processor.id}}}

        {:ok, capability} ->
          if MapSet.subset?(
               MapSet.new(processor.requested_permissions),
               MapSet.new(capability.permissions)
             ) do
            {:cont, :ok}
          else
            {:halt, {:error, {:processor_permissions_exceed_capability, processor.id}}}
          end
      end
    end)
  end

  defp validate_default_processors(processors) do
    duplicate =
      processors
      |> Map.values()
      |> Enum.filter(& &1.default)
      |> Enum.group_by(&{&1.capability_id, &1.capability_contract_version})
      |> Enum.find(fn {_capability, defaults} -> length(defaults) > 1 end)

    case duplicate do
      nil -> :ok
      {capability, _defaults} -> {:error, {:multiple_default_processors, capability}}
    end
  end
end
