defmodule Contexla.Platform.Applications do
  @moduledoc """
  Platform services for installed Applications and their configured Instances.

  Bundled package definitions remain code-authoritative. This context persists
  only configured Instances and pins the Application version used to create
  them.
  """

  import Ecto.Query, warn: false

  alias Contexla.Platform.Accounts.Scope
  alias Contexla.Platform.Applications.ApplicationInstance
  alias Contexla.Platform.AuditEvents
  alias Contexla.Platform.Packages.Registry
  alias Contexla.Platform.Repo

  @doc "Returns definitions for Applications installed in this release."
  def list_installed_applications(%Scope{user: %Contexla.Platform.Accounts.User{}}) do
    Registry.applications()
  end

  @doc "Lists all Application Instances in this single-organization installation."
  def list_instances(%Scope{user: %Contexla.Platform.Accounts.User{}}) do
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
  def get_instance!(%Scope{user: %Contexla.Platform.Accounts.User{}}, id) do
    instance = Repo.get!(ApplicationInstance, id)

    case ensure_compatible(instance) do
      {:ok, compatible} ->
        compatible

      {:error, reason} ->
        raise ArgumentError, "incompatible Application Instance: #{inspect(reason)}"
    end
  end

  @doc "Fetches an Application Instance without raising."
  def fetch_instance(%Scope{user: %Contexla.Platform.Accounts.User{}}, id) do
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
        %Scope{user: %Contexla.Platform.Accounts.User{} = user} = scope,
        %{"application_id" => application_id} = attrs
      ) do
    with {:ok, definition} <- Registry.fetch_application(application_id),
         config when is_map(config) <- Map.get(attrs, "config", %{}),
         {:ok, normalized_config} <- definition.entry_module.validate_instance_config(config) do
      attrs = Map.put(attrs, "config", normalized_config)

      changeset =
        %ApplicationInstance{}
        |> ApplicationInstance.create_changeset(attrs, definition, user)

      persist_with_audit(changeset, scope, :insert, fn instance ->
        %{
          action: "application_instance.created",
          subject_type: "application_instance",
          subject_id: instance.id,
          application_instance_id: instance.id,
          metadata: %{
            "application_id" => instance.application_id,
            "application_version" => instance.application_version
          }
        }
      end)
    else
      {:error, :not_found} -> {:error, :application_not_installed}
      {:error, reason} -> {:error, {:invalid_instance_config, reason}}
      _invalid_config -> {:error, {:invalid_instance_config, :must_be_a_map}}
    end
  end

  def create_instance(%Scope{user: %Contexla.Platform.Accounts.User{}}, _attrs) do
    {:error, :application_id_required}
  end

  def change_instance_settings(%Scope{} = scope, id, attrs \\ %{}) do
    with {:ok, instance} <- fetch_instance(scope, id) do
      {:ok, ApplicationInstance.settings_changeset(instance, attrs)}
    end
  end

  def update_instance_settings(%Scope{} = scope, id, attrs) do
    with {:ok, instance} <- fetch_instance(scope, id) do
      changeset = ApplicationInstance.settings_changeset(instance, attrs)

      changed_fields =
        changeset.changes |> Map.keys() |> Enum.map(&Atom.to_string/1) |> Enum.sort()

      persist_with_audit(changeset, scope, :update, fn updated ->
        %{
          action: "application_instance.settings_updated",
          subject_type: "application_instance",
          subject_id: updated.id,
          application_instance_id: updated.id,
          metadata: %{"changed_fields" => changed_fields}
        }
      end)
    end
  end

  def update_instance_config(%Scope{} = scope, id, config) when is_map(config) do
    with {:ok, instance} <- fetch_instance(scope, id),
         {:ok, definition} <- Registry.fetch_application(instance.application_id),
         {:ok, normalized_config} <- definition.entry_module.validate_instance_config(config) do
      changeset = ApplicationInstance.config_changeset(instance, normalized_config)

      persist_with_audit(changeset, scope, :update, fn updated ->
        %{
          action: "application_instance.configuration_updated",
          subject_type: "application_instance",
          subject_id: updated.id,
          application_instance_id: updated.id,
          metadata: %{"config_keys" => normalized_config |> Map.keys() |> Enum.sort()}
        }
      end)
    end
  end

  defp persist_with_audit(changeset, scope, operation, event_attrs) do
    Repo.transaction(fn ->
      with {:ok, instance} <- apply(Repo, operation, [changeset]),
           {:ok, _event} <- AuditEvents.record(scope, event_attrs.(instance)) do
        instance
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp settings_path(application_id) do
    case Registry.fetch_settings_surface(application_id) do
      {:ok, surface} -> surface.path
      {:error, :not_found} -> nil
    end
  end
end
