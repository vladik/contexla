defmodule Contexla.Packages.Registry do
  @moduledoc """
  Runtime registry for independently compiled trusted packages.

  Development registrations and installed packages are loaded through metadata;
  the platform never compiles against a concrete Application module.
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

  def fetch_application_entry(id), do: GenServer.call(__MODULE__, {:fetch_application_entry, id})

  def fetch_surface(id, path, role \\ nil) do
    GenServer.call(__MODULE__, {:fetch_surface, id, path, role})
  end

  def fetch_default_surface(id) do
    GenServer.call(__MODULE__, {:fetch_default_surface, id})
  end

  def fetch_settings_surface(id) do
    GenServer.call(__MODULE__, {:fetch_settings_surface, id})
  end

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

  def handle_call({:fetch_application_entry, id}, _from, state) do
    result =
      case Map.fetch(state.applications, id) do
        {:ok, {module, definition}} -> {:ok, {module, definition}}
        :error -> {:error, :not_found}
      end

    {:reply, result, state}
  end

  def handle_call({:fetch_surface, id, path, role}, _from, state) do
    result =
      with {:ok, {_module, definition}} <- Map.fetch(state.applications, id),
           surface when not is_nil(surface) <-
             Enum.find(definition.surfaces, fn surface ->
               surface.path == path and (is_nil(role) or surface.role == role)
             end),
           true <- Code.ensure_loaded?(surface.module) do
        {:ok, surface}
      else
        _ -> {:error, :not_found}
      end

    {:reply, result, state}
  end

  def handle_call({:fetch_default_surface, id}, _from, state) do
    result =
      with {:ok, {_module, definition}} <- Map.fetch(state.applications, id),
           surface when not is_nil(surface) <-
             Enum.find(definition.surfaces, &(&1.role == :instance and &1.default)),
           true <- Code.ensure_loaded?(surface.module) do
        {:ok, surface}
      else
        _ -> {:error, :not_found}
      end

    {:reply, result, state}
  end

  def handle_call({:fetch_settings_surface, id}, _from, state) do
    result =
      with {:ok, {_module, definition}} <- Map.fetch(state.applications, id),
           surface when not is_nil(surface) <-
             Enum.find(definition.surfaces, &(&1.role == :instance and &1.kind == :settings)),
           true <- Code.ensure_loaded?(surface.module) do
        {:ok, surface}
      else
        _ -> {:error, :not_found}
      end

    {:reply, result, state}
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
    |> load_packages(&load_application/1)
  end

  defp load_integrations do
    :contexla
    |> Application.get_env(:integration_packages, [])
    |> load_packages(&load_integration/1)
  end

  defp load_packages(modules, validator) do
    Enum.reduce_while(modules, {:ok, %{}}, fn registration, {:ok, packages} ->
      case validator.(registration) do
        {:ok, definition} ->
          if Map.has_key?(packages, definition.id) do
            {:halt, {:error, {:duplicate_package_id, definition.id}}}
          else
            module = definition.entry_module
            {:cont, {:ok, Map.put(packages, definition.id, {module, definition})}}
          end

        {:error, reason} ->
          {:halt, {:error, {:invalid_package, registration, reason}}}
      end
    end)
  end

  defp load_application(module) when is_atom(module), do: ApplicationSDK.validate_module(module)

  defp load_application(%{ebin: ebin, entry_module: entry_module}) do
    module = Module.concat([entry_module])

    with true <- Code.append_path(String.to_charlist(ebin)),
         true <- Code.ensure_loaded?(module),
         {:ok, definition} <- ApplicationSDK.validate_module(module),
         :ok <- load_otp_application(definition.otp_application),
         :ok <- migrate_application(module) do
      {:ok, definition}
    else
      false -> {:error, :entry_module_not_loaded}
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_integration(module) when is_atom(module), do: IntegrationSDK.validate_module(module)

  defp load_integration(%{ebin: ebin, entry_module: entry_module}) do
    module = Module.concat([entry_module])

    with true <- Code.append_path(String.to_charlist(ebin)),
         true <- Code.ensure_loaded?(module),
         {:ok, definition} <- IntegrationSDK.validate_module(module),
         :ok <- load_otp_application(definition.otp_application) do
      {:ok, definition}
    else
      false -> {:error, :entry_module_not_loaded}
      {:error, reason} -> {:error, reason}
    end
  end

  defp migrate_application(module) do
    if function_exported?(module, :migrate_install, 1) do
      module.migrate_install(Contexla.Repo)
    else
      :ok
    end
  end

  defp load_otp_application(application) do
    case Application.load(application) do
      :ok -> :ok
      {:error, {:already_loaded, ^application}} -> :ok
      {:error, reason} -> {:error, {:application_load_failed, reason}}
    end
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
