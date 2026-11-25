defmodule Contexla.Platform.SourceImports do
  @moduledoc """
  Orchestrates validation and storage of an offline source package.

  Source interpretation remains in the selected Integration Adapter. The
  platform authorizes the actor and Instance, verifies contract compatibility,
  and stores the validated package as an immutable Artifact.
  """

  alias Contexla.Platform.Accounts.Scope
  alias Contexla.Platform.Applications
  alias Contexla.Platform.Artifacts
  alias Contexla.Platform.AuditEvents
  alias Contexla.Platform.Packages.Registry
  alias Contexla.Platform.Repo

  @spec import(
          Scope.t(),
          Ecto.UUID.t(),
          String.t(),
          Path.t(),
          keyword()
        ) :: {:ok, Contexla.Platform.Artifacts.Artifact.t()} | {:error, term()}
  def import(
        %Scope{user: %Contexla.Platform.Accounts.User{}} = scope,
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
           store_with_audit(scope, instance, adapter, source_path, validation, metadata, opts) do
      {:ok, artifact}
    else
      {:error, :not_found} -> {:error, :adapter_not_installed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp store_with_audit(scope, instance, adapter, source_path, validation, metadata, opts) do
    Repo.transaction(fn ->
      with {:ok, artifact} <-
             Artifacts.store_validated_source(scope, instance, source_path, validation, %{
               kind: "source_snapshot",
               filename: Keyword.get(opts, :filename, Path.basename(source_path)),
               media_type: "application/zip",
               metadata: metadata
             }),
           {:ok, _event} <-
             AuditEvents.record(scope, %{
               action: "source_snapshot.imported",
               subject_type: "artifact",
               subject_id: artifact.id,
               application_instance_id: instance.id,
               metadata: %{
                 "adapter_id" => adapter.id,
                 "artifact_sha256" => artifact.sha256
               }
             }) do
        artifact
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp ensure_contract(application, adapter) do
    if adapter.contract in application.required_adapter_contracts do
      :ok
    else
      {:error, {:adapter_contract_mismatch, adapter.contract}}
    end
  end
end
