defmodule Contexla.Applications do
  @moduledoc """
  Platform services for installed Applications and their configured Instances.

  Bundled package definitions remain code-authoritative. This context persists
  only configured Instances and pins the Application version used to create
  them.
  """

  import Ecto.Query, warn: false

  alias Contexla.Accounts.Scope
  alias Contexla.Applications.ApplicationInstance
  alias Contexla.Packages.Registry
  alias Contexla.Repo

  @doc "Returns definitions for Applications installed in this release."
  def list_installed_applications(%Scope{user: %Contexla.Accounts.User{}}) do
    Registry.applications()
  end

  @doc "Lists all Application Instances in this single-organization installation."
  def list_instances(%Scope{user: %Contexla.Accounts.User{}}) do
    ApplicationInstance
    |> order_by([instance], asc: instance.name)
    |> Repo.all()
  end

  @doc "Lists generic Instance navigation entries with their Application icons."
  def list_navigation_instances(%Scope{} = scope) do
    icons = Map.new(Registry.applications(), &{&1.id, &1.icon})

    scope
    |> list_instances()
    |> Enum.map(fn instance ->
      %{
        id: instance.id,
        name: instance.name,
        description: instance.description,
        application_id: instance.application_id,
        icon: instance.icon || Map.get(icons, instance.application_id, "hero-cube"),
        settings_path: settings_path(instance.application_id)
      }
    end)
  end

  @doc "Gets an Application Instance visible in this installation."
  def get_instance!(%Scope{user: %Contexla.Accounts.User{}}, id) do
    instance = Repo.get!(ApplicationInstance, id)

    case ensure_compatible(instance) do
      {:ok, compatible} ->
        compatible

      {:error, reason} ->
        raise ArgumentError, "incompatible Application Instance: #{inspect(reason)}"
    end
  end

  @doc "Fetches an Application Instance without raising."
  def fetch_instance(%Scope{user: %Contexla.Accounts.User{}}, id) do
    case Repo.get(ApplicationInstance, id) do
      nil -> {:error, :instance_not_found}
      instance -> ensure_compatible(instance)
    end
  end

  @doc "Checks that an Instance can run against the exact installed Application version."
  def ensure_compatible(%ApplicationInstance{} = instance) do
    case Registry.fetch_application(instance.application_id) do
      {:ok, %{version: version}} when version == instance.application_version ->
        {:ok, instance}

      {:ok, %{version: installed_version}} ->
        {:error,
         {:application_version_mismatch,
          %{pinned: instance.application_version, installed: installed_version}}}

      {:error, :not_found} ->
        {:error, :application_not_installed}
    end
  end

  @doc """
  Creates an Instance after validating its configuration through the installed
  Application package.
  """
  def create_instance(
        %Scope{user: %Contexla.Accounts.User{} = user},
        %{"application_id" => application_id} = attrs
      ) do
    with {:ok, definition} <- Registry.fetch_application(application_id),
         config when is_map(config) <- Map.get(attrs, "config", %{}),
         {:ok, normalized_config} <- definition.entry_module.validate_instance_config(config) do
      attrs = Map.put(attrs, "config", normalized_config)

      %ApplicationInstance{}
      |> ApplicationInstance.create_changeset(attrs, definition, user)
      |> Repo.insert()
    else
      {:error, :not_found} -> {:error, :application_not_installed}
      {:error, reason} -> {:error, {:invalid_instance_config, reason}}
      _invalid_config -> {:error, {:invalid_instance_config, :must_be_a_map}}
    end
  end

  def create_instance(%Scope{user: %Contexla.Accounts.User{}}, _attrs) do
    {:error, :application_id_required}
  end

  def change_instance_settings(%Scope{} = scope, id, attrs \\ %{}) do
    with {:ok, instance} <- fetch_instance(scope, id) do
      {:ok, ApplicationInstance.settings_changeset(instance, attrs)}
    end
  end

  def update_instance_settings(%Scope{} = scope, id, attrs) do
    with {:ok, instance} <- fetch_instance(scope, id) do
      instance
      |> ApplicationInstance.settings_changeset(attrs)
      |> Repo.update()
    end
  end

  def update_instance_config(%Scope{} = scope, id, config) when is_map(config) do
    with {:ok, instance} <- fetch_instance(scope, id),
         {:ok, definition} <- Registry.fetch_application(instance.application_id),
         {:ok, normalized_config} <- definition.entry_module.validate_instance_config(config) do
      instance
      |> ApplicationInstance.config_changeset(normalized_config)
      |> Repo.update()
    end
  end

  defp settings_path(application_id) do
    case Registry.fetch_settings_surface(application_id) do
      {:ok, surface} -> surface.path
      {:error, :not_found} -> nil
    end
  end
end
