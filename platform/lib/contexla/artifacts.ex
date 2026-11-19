defmodule Contexla.Artifacts do
  @moduledoc """
  Platform services for immutable, evidence-bearing files.
  """

  alias Contexla.Accounts.Scope
  alias Contexla.Applications.ApplicationInstance
  alias Contexla.Artifacts.{Artifact, Storage}
  alias Contexla.Repo

  @doc false
  def store_validated_source(
        %Scope{user: %Contexla.Accounts.User{} = user},
        %ApplicationInstance{} = instance,
        source_path,
        validation,
        attrs
      ) do
    kind = Map.fetch!(attrs, :kind)

    case Repo.get_by(Artifact,
           application_instance_id: instance.id,
           kind: kind,
           sha256: validation.sha256
         ) do
      %Artifact{} = artifact ->
        {:ok, artifact}

      nil ->
        with {:ok, storage_key} <-
               Storage.persist(source_path, validation.sha256, validation.byte_size) do
          artifact_attrs = %{
            kind: kind,
            source_type: validation.source_type,
            filename: safe_filename(Map.fetch!(attrs, :filename)),
            media_type: Map.get(attrs, :media_type, "application/zip"),
            sha256: validation.sha256,
            byte_size: validation.byte_size,
            storage_key: storage_key,
            metadata: Map.fetch!(attrs, :metadata)
          }

          %Artifact{}
          |> Artifact.create_changeset(artifact_attrs, instance, user)
          |> Repo.insert()
        end
    end
  end

  @doc "Returns the managed local path for an Artifact."
  def local_path(%Artifact{storage_key: storage_key}), do: Storage.path_for_key(storage_key)

  defp safe_filename(filename) do
    filename
    |> to_string()
    |> Path.basename()
    |> String.slice(0, 255)
  end
end
