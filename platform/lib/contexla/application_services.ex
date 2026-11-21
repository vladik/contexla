defmodule Contexla.ApplicationServices do
  @moduledoc "Platform services exposed to trusted Applications through the SDK."

  @behaviour Contexla.ApplicationSDK.PlatformServices

  alias Contexla.Accounts.{Scope, User}

  alias Contexla.{
    ApplicationOperations,
    Applications,
    Artifacts,
    Capabilities,
    Repo,
    SourceImports
  }

  alias Contexla.Packages.Registry

  def create_instance(actor_id, attrs), do: Applications.create_instance(scope!(actor_id), attrs)
  def get_instance(actor_id, id), do: Applications.fetch_instance(scope!(actor_id), id)

  def update_instance_config(actor_id, id, config),
    do: Applications.update_instance_config(scope!(actor_id), id, config)

  def get_artifact(actor_id, id), do: Artifacts.fetch(scope!(actor_id), id)

  def list_artifacts(actor_id, instance_id),
    do: Artifacts.list_for_instance(scope!(actor_id), instance_id)

  def import_source(actor_id, instance_id, adapter_id, path, options) do
    SourceImports.import(scope!(actor_id), instance_id, adapter_id, path, options)
  end

  def artifact_path(artifact), do: Artifacts.local_path(artifact)
  def fetch_adapter(adapter_id), do: Registry.fetch_adapter(adapter_id)

  def invoke_capability(actor_id, instance_id, key, version, input) do
    scope = scope!(actor_id)

    with {:ok, instance} <- Applications.fetch_instance(scope, instance_id) do
      Capabilities.invoke(scope, instance, key, version, input)
    end
  end

  def invoke_operation(actor_id, instance_id, operation_id, input, options \\ []) do
    ApplicationOperations.invoke(
      scope!(actor_id),
      instance_id,
      operation_id,
      input,
      options
    )
  end

  def enqueue(worker, args) when is_atom(worker) and is_map(args) do
    worker.new(args) |> Oban.insert()
  end

  defp scope!(actor_id), do: Scope.for_user(Repo.get!(User, actor_id))
end
