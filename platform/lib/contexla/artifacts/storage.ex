defmodule Contexla.Artifacts.Storage do
  @moduledoc """
  Content-addressed local Artifact storage.

  The original filename never participates in a storage path. Callers provide
  the hash and size produced by source validation; this module verifies them
  again while copying to prevent validation/storage drift.
  """

  @chunk_bytes 64 * 1024

  @spec persist(Path.t(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, term()}
  def persist(source_path, expected_sha256, expected_bytes) do
    storage_key = Path.join(["sha256", String.slice(expected_sha256, 0, 2), expected_sha256])
    destination = path_for_key(storage_key)

    with :ok <- File.mkdir_p(Path.dirname(destination)),
         :ok <- persist_or_verify(source_path, destination, expected_sha256, expected_bytes) do
      {:ok, storage_key}
    end
  end

  @spec path_for_key(String.t()) :: Path.t()
  def path_for_key(storage_key) do
    root = storage_root()
    expanded = Path.expand(storage_key, root)

    if expanded == root or String.starts_with?(expanded, [root <> "/", root <> "\\"]) do
      expanded
    else
      raise ArgumentError, "artifact storage key escapes its configured root"
    end
  end

  defp persist_or_verify(source, destination, sha256, bytes) do
    if File.exists?(destination) do
      verify_file(destination, sha256, bytes)
    else
      temporary = destination <> ".#{System.unique_integer([:positive])}.tmp"

      result =
        with :ok <- File.cp(source, temporary),
             :ok <- verify_file(temporary, sha256, bytes),
             :ok <- move_into_place(temporary, destination),
             :ok <- verify_file(destination, sha256, bytes) do
          :ok
        end

      File.rm(temporary)
      result
    end
  end

  defp move_into_place(temporary, destination) do
    case File.rename(temporary, destination) do
      :ok -> :ok
      {:error, :eexist} -> :ok
      {:error, reason} -> {:error, {:artifact_move_failed, reason}}
    end
  end

  defp verify_file(path, expected_sha256, expected_bytes) do
    with {:ok, %{type: :regular, size: ^expected_bytes}} <- File.stat(path),
         {:ok, ^expected_sha256} <- sha256(path) do
      :ok
    else
      {:ok, %{size: actual}} ->
        {:error, {:artifact_size_changed, actual, expected_bytes}}

      {:ok, actual_sha256} ->
        {:error, {:artifact_checksum_changed, actual_sha256, expected_sha256}}

      {:error, reason} ->
        {:error, {:artifact_verification_failed, reason}}
    end
  end

  defp sha256(path) do
    digest =
      path
      |> File.stream!(@chunk_bytes, [])
      |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()
      |> Base.encode16(case: :lower)

    {:ok, digest}
  rescue
    _error -> {:error, :artifact_storage_failed}
  end

  defp storage_root do
    :contexla
    |> Application.fetch_env!(:artifact_storage_path)
    |> Path.expand()
  end
end
