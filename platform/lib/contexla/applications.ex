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

  @doc "Gets an Application Instance visible in this installation."
  def get_instance!(%Scope{user: %Contexla.Accounts.User{}}, id) do
    Repo.get!(ApplicationInstance, id)
  end

  @doc "Fetches an Application Instance without raising."
  def fetch_instance(%Scope{user: %Contexla.Accounts.User{}}, id) do
    case Repo.get(ApplicationInstance, id) do
      nil -> {:error, :instance_not_found}
      instance -> {:ok, instance}
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
end
