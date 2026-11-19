defmodule Contexla.Packages.Registry do
  @moduledoc """
  Runtime registry for trusted Application and Integration packages bundled
  into the Contexla release.

  The registry validates package definitions at startup. It does not implement
  dynamic package installation; that lifecycle is deliberately deferred.
  """

  use GenServer

  alias Contexla.ApplicationSDK
  alias Contexla.IntegrationSDK

  @type package_id :: String.t()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec applications() :: [ApplicationSDK.Definition.t()]
  def applications, do: GenServer.call(__MODULE__, :applications)

  @spec integrations() :: [IntegrationSDK.Definition.t()]
  def integrations, do: GenServer.call(__MODULE__, :integrations)

  @spec fetch_application(package_id()) ::
          {:ok, ApplicationSDK.Definition.t()} | {:error, :not_found}
  def fetch_application(id), do: GenServer.call(__MODULE__, {:fetch_application, id})

  @spec fetch_integration(package_id()) ::
          {:ok, IntegrationSDK.Definition.t()} | {:error, :not_found}
  def fetch_integration(id), do: GenServer.call(__MODULE__, {:fetch_integration, id})

  @spec fetch_adapter(String.t()) ::
          {:ok, {IntegrationSDK.Definition.t(), IntegrationSDK.Adapter.t()}}
          | {:error, :not_found}
  def fetch_adapter(id), do: GenServer.call(__MODULE__, {:fetch_adapter, id})

  @impl true
  def init(_opts) do
    with {:ok, applications} <- load_applications(),
         {:ok, integrations} <- load_integrations() do
      {:ok, %{applications: applications, integrations: integrations}}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call(:applications, _from, state) do
    {:reply, definitions(state.applications), state}
  end

  def handle_call(:integrations, _from, state) do
    {:reply, definitions(state.integrations), state}
  end

  def handle_call({:fetch_application, id}, _from, state) do
    {:reply, fetch_definition(state.applications, id), state}
  end

  def handle_call({:fetch_integration, id}, _from, state) do
    {:reply, fetch_definition(state.integrations, id), state}
  end

  def handle_call({:fetch_adapter, id}, _from, state) do
    result =
      state.integrations
      |> Map.values()
      |> Enum.find_value(fn {_module, definition} ->
        case Enum.find(definition.adapters, &(&1.id == id)) do
          nil -> nil
          adapter -> {:ok, {definition, adapter}}
        end
      end)
      |> then(&(&1 || {:error, :not_found}))

    {:reply, result, state}
  end

  defp load_applications do
    :contexla
    |> Application.get_env(:application_packages, [])
    |> load_packages(&ApplicationSDK.validate_module/1)
  end

  defp load_integrations do
    :contexla
    |> Application.get_env(:integration_packages, [])
    |> load_packages(&IntegrationSDK.validate_module/1)
  end

  defp load_packages(modules, validator) do
    Enum.reduce_while(modules, {:ok, %{}}, fn module, {:ok, packages} ->
      case validator.(module) do
        {:ok, definition} ->
          if Map.has_key?(packages, definition.id) do
            {:halt, {:error, {:duplicate_package_id, definition.id}}}
          else
            {:cont, {:ok, Map.put(packages, definition.id, {module, definition})}}
          end

        {:error, reason} ->
          {:halt, {:error, {:invalid_package, module, reason}}}
      end
    end)
  end

  defp definitions(packages) do
    packages
    |> Map.values()
    |> Enum.map(fn {_module, definition} -> definition end)
    |> Enum.sort_by(& &1.name)
  end

  defp fetch_definition(packages, id) do
    case Map.fetch(packages, id) do
      {:ok, {_module, definition}} -> {:ok, definition}
      :error -> {:error, :not_found}
    end
  end
end
