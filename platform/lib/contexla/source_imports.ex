defmodule Contexla.SourceImports do
  @moduledoc """
  Orchestrates validation and storage of an offline source package.

  Source interpretation remains in the selected Integration Adapter. The
  platform authorizes the actor and Instance, verifies contract compatibility,
  and stores the validated package as an immutable Artifact.
  """

  alias Contexla.Accounts.Scope
  alias Contexla.Applications
  alias Contexla.Artifacts
  alias Contexla.Packages.Registry

  @spec import(
          Scope.t(),
          Ecto.UUID.t(),
          String.t(),
          Path.t(),
          keyword()
        ) :: {:ok, Contexla.Artifacts.Artifact.t()} | {:error, term()}
  def import(
        %Scope{user: %Contexla.Accounts.User{}} = scope,
        instance_id,
        adapter_id,
        source_path,
        opts \\ []
      ) do
    with {:ok, instance} <- Applications.fetch_instance(scope, instance_id),
         {:ok, application} <- Registry.fetch_application(instance.application_id),
         {:ok, {integration, adapter}} <- Registry.fetch_adapter(adapter_id),
         :ok <- ensure_contract(application, adapter),
         {:ok, validation} <- adapter.module.validate_source(source_path, opts),
         metadata = %{
           "integration_id" => integration.id,
           "integration_version" => integration.version,
           "adapter_id" => adapter.id,
           "manifest" => validation.manifest,
           "files" => validation.files
         },
         {:ok, artifact} <-
           Artifacts.store_validated_source(scope, instance, source_path, validation, %{
             kind: "source_snapshot",
             filename: Keyword.get(opts, :filename, Path.basename(source_path)),
             media_type: "application/zip",
             metadata: metadata
           }) do
      {:ok, artifact}
    else
      {:error, :not_found} -> {:error, :adapter_not_installed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_contract(application, adapter) do
    if adapter.contract in application.required_adapter_contracts do
      :ok
    else
      {:error, {:adapter_contract_mismatch, adapter.contract}}
    end
  end
end
