defmodule Contexla.Platform.Artifacts do
  @moduledoc """
  Platform services for immutable, evidence-bearing files.
  """

  alias Contexla.Platform.Accounts.Scope
  alias Contexla.Platform.Applications.ApplicationInstance
  alias Contexla.Platform.Artifacts.{Artifact, Storage}
  alias Contexla.Platform.Repo

  import Ecto.Query, warn: false

  def fetch(%Scope{user: %Contexla.Platform.Accounts.User{}}, id) do
    case Repo.get(Artifact, id) do
      nil -> {:error, :not_found}
      artifact -> {:ok, artifact}
    end
  end

  def list_for_instance(%Scope{user: %Contexla.Platform.Accounts.User{}}, instance_id) do
    Artifact
    |> where([artifact], artifact.application_instance_id == ^instance_id)
    |> where([artifact], artifact.kind != "tool_input")
    |> order_by([artifact], desc: artifact.inserted_at)
    |> Repo.all()
  end

  @doc false
  def store_validated_source(
        %Scope{user: %Contexla.Platform.Accounts.User{} = user},
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

  @doc false
  def store_tool_input(
        %Scope{user: %Contexla.Platform.Accounts.User{} = user},
        %ApplicationInstance{} = instance,
        input
      )
      when is_map(input) do
    encoded = Jason.encode!(input)
    sha256 = :crypto.hash(:sha256, encoded) |> Base.encode16(case: :lower)
    byte_size = byte_size(encoded)

    case Repo.get_by(Artifact,
           application_instance_id: instance.id,
           kind: "tool_input",
           sha256: sha256
         ) do
      %Artifact{} = artifact ->
        {:ok, artifact}

      nil ->
        temporary =
          Path.join(
            System.tmp_dir!(),
            "contexla-tool-input-#{System.unique_integer([:positive])}.json"
          )

        try do
          with :ok <- File.write(temporary, encoded, [:binary, :exclusive]),
               {:ok, storage_key} <- Storage.persist(temporary, sha256, byte_size) do
            attrs = %{
              kind: "tool_input",
              source_type: "tool_runtime",
              filename: "tool-input-#{sha256}.json",
              media_type: "application/json",
              sha256: sha256,
              byte_size: byte_size,
              storage_key: storage_key,
              metadata: %{"internal" => true}
            }

            %Artifact{}
            |> Artifact.create_changeset(attrs, instance, user)
            |> Repo.insert()
          end
        after
          File.rm(temporary)
        end
    end
  end

  defp safe_filename(filename) do
    filename
    |> to_string()
    |> Path.basename()
    |> String.slice(0, 255)
  end
end
