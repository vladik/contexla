defmodule Contexla.Integrations.Drupal.Snapshot.Validator do
  @moduledoc """
  Security and contract validation for an offline Drupal snapshot ZIP.

  The archive directory is inspected before files are expanded. Validation is
  performed in memory; archive contents are never executed or extracted to the
  filesystem.
  """

  @contract "contexla.estate-evidence-package"
  @contract_version "1.0"
  @profile "contexla.drupal-snapshot"
  @profile_version "1.0"
  @source_type "contexla.drupal-snapshot.v1"

  @default_limits %{
    archive_bytes: 50 * 1024 * 1024,
    file_count: 1_000,
    file_bytes: 25 * 1024 * 1024,
    total_uncompressed_bytes: 200 * 1024 * 1024,
    compression_ratio: 200
  }

  @spec validate(Path.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def validate(path, opts \\ []) when is_binary(path) do
    limits = Map.merge(@default_limits, Map.new(Keyword.get(opts, :limits, [])))

    with {:ok, stat} <- regular_file(path),
         :ok <- within_limit(:archive_bytes, stat.size, limits.archive_bytes),
         {:ok, entries} <- archive_entries(path),
         :ok <- validate_entries(entries, limits),
         {:ok, extracted} <- extract_to_memory(path),
         {:ok, manifest_json} <- fetch_file(extracted, "manifest.json"),
         {:ok, manifest} <- decode_manifest(manifest_json),
         :ok <- validate_manifest(manifest),
         {:ok, files} <- validate_declared_files(manifest, extracted),
         {:ok, sha256} <- file_sha256(path) do
      {:ok,
       %{
         sha256: sha256,
         byte_size: stat.size,
         source_type: @source_type,
         manifest: manifest,
         files: files
       }}
    end
  end

  @doc "Validates a snapshot and returns decoded declared JSON documents."
  @spec validate_and_read(Path.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def validate_and_read(path, opts \\ []) when is_binary(path) do
    with {:ok, validation} <- validate(path, opts),
         {:ok, extracted} <- extract_to_memory(path),
         {:ok, documents} <- decode_declared_json(validation.files, extracted) do
      {:ok, Map.put(validation, :documents, documents)}
    end
  end

  defp regular_file(path) do
    case File.stat(path) do
      {:ok, %{type: :regular} = stat} -> {:ok, stat}
      {:ok, _stat} -> {:error, :source_not_regular_file}
      {:error, reason} -> {:error, {:source_unavailable, reason}}
    end
  end

  defp archive_entries(path) do
    case :zip.list_dir(String.to_charlist(path)) do
      {:ok, [_comment | entries]} -> normalize_entries(entries)
      {:error, reason} -> {:error, {:invalid_zip, reason}}
    end
  rescue
    error -> {:error, {:invalid_zip, Exception.message(error)}}
  end

  defp normalize_entries(entries) do
    Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, normalized} ->
      case normalize_entry(entry) do
        {:ok, item} -> {:cont, {:ok, [item | normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp normalize_entry({:zip_file, name, file_info, _comment, _offset, compressed_bytes}) do
    with {:ok, path} <- normalize_path(name) do
      {:ok,
       %{
         path: path,
         type: elem(file_info, 2),
         bytes: elem(file_info, 1),
         compressed_bytes: compressed_bytes
       }}
    end
  end

  defp normalize_entry(_entry), do: {:error, :unsupported_zip_entry}

  defp normalize_path(name) when is_list(name) do
    name
    |> List.to_string()
    |> String.replace("\\", "/")
    |> validate_path()
  rescue
    _error -> {:error, :invalid_zip_path_encoding}
  end

  defp validate_path(path) do
    segments = String.split(path, "/", trim: true)

    cond do
      path == "" -> {:error, :empty_zip_path}
      String.contains?(path, <<0>>) -> {:error, {:unsafe_zip_path, path}}
      String.starts_with?(path, "/") -> {:error, {:unsafe_zip_path, path}}
      Regex.match?(~r/^[A-Za-z]:/, path) -> {:error, {:unsafe_zip_path, path}}
      Enum.any?(segments, &(&1 in [".", ".."])) -> {:error, {:unsafe_zip_path, path}}
      true -> {:ok, Enum.join(segments, "/")}
    end
  end

  defp validate_entries(entries, limits) do
    files = Enum.filter(entries, &(&1.type == :regular))

    with :ok <- within_limit(:file_count, length(files), limits.file_count),
         :ok <- unique_paths(entries),
         :ok <- validate_file_limits(files, limits),
         total = Enum.sum(Enum.map(files, & &1.bytes)),
         :ok <-
           within_limit(
             :total_uncompressed_bytes,
             total,
             limits.total_uncompressed_bytes
           ) do
      :ok
    end
  end

  defp unique_paths(entries) do
    downcased = Enum.map(entries, &String.downcase(&1.path))

    if length(downcased) == length(Enum.uniq(downcased)) do
      :ok
    else
      {:error, :duplicate_zip_path}
    end
  end

  defp validate_file_limits(files, limits) do
    Enum.reduce_while(files, :ok, fn file, :ok ->
      ratio =
        if file.compressed_bytes == 0, do: file.bytes, else: file.bytes / file.compressed_bytes

      with :ok <- within_limit({:file_bytes, file.path}, file.bytes, limits.file_bytes),
           :ok <-
             within_limit(
               {:compression_ratio, file.path},
               ratio,
               limits.compression_ratio
             ) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp within_limit(_name, value, limit) when value <= limit, do: :ok
  defp within_limit(name, value, limit), do: {:error, {:limit_exceeded, name, value, limit}}

  defp extract_to_memory(path) do
    case :zip.extract(String.to_charlist(path), [:memory]) do
      {:ok, files} ->
        files
        |> Enum.reduce_while({:ok, %{}}, fn {name, body}, {:ok, extracted} ->
          with {:ok, normalized} <- normalize_path(name) do
            {:cont, {:ok, Map.put(extracted, normalized, body)}}
          else
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:error, reason} ->
        {:error, {:invalid_zip, reason}}
    end
  end

  defp fetch_file(files, path) do
    case Map.fetch(files, path) do
      {:ok, body} -> {:ok, body}
      :error -> {:error, {:required_file_missing, path}}
    end
  end

  defp decode_manifest(json) do
    case Jason.decode(json) do
      {:ok, manifest} when is_map(manifest) -> {:ok, manifest}
      {:ok, _other} -> {:error, :manifest_must_be_an_object}
      {:error, error} -> {:error, {:invalid_manifest_json, Exception.message(error)}}
    end
  end

  defp decode_declared_json(files, extracted) do
    files
    |> Enum.filter(&(&1["media_type"] == "application/json"))
    |> Enum.reduce_while({:ok, %{}}, fn declaration, {:ok, decoded} ->
      path = declaration["path"]

      case Jason.decode(Map.fetch!(extracted, path)) do
        {:ok, document} ->
          {:cont, {:ok, Map.put(decoded, path, document)}}

        {:error, error} ->
          {:halt, {:error, {:invalid_declared_json, path, Exception.message(error)}}}
      end
    end)
  end

  defp validate_manifest(manifest) do
    validators = [
      manifest["contract"] == @contract,
      manifest["version"] == @contract_version,
      get_in(manifest, ["profile", "id"]) == @profile,
      get_in(manifest, ["profile", "version"]) == @profile_version,
      non_empty_string?(manifest["package_id"]),
      valid_timestamp?(manifest["created_at"]),
      is_map(manifest["producer"]),
      get_in(manifest, ["source", "system"]) == "drupal",
      non_empty_string?(get_in(manifest, ["source", "installation_id"])),
      non_empty_string?(get_in(manifest, ["collection", "mode"])),
      non_empty_string?(manifest["classification"]),
      is_list(manifest["files"])
    ]

    if Enum.all?(validators), do: :ok, else: {:error, :invalid_manifest_contract}
  end

  defp validate_declared_files(manifest, extracted) do
    declarations = manifest["files"]

    with {:ok, declared} <- index_declarations(declarations),
         archive_paths = extracted |> Map.delete("manifest.json") |> Map.keys() |> MapSet.new(),
         declared_paths = declared |> Map.keys() |> MapSet.new(),
         :ok <- equal_file_sets(declared_paths, archive_paths),
         :ok <- verify_declared_files(declared, extracted) do
      files =
        declared
        |> Map.values()
        |> Enum.map(&Map.take(&1, ["path", "kind", "media_type", "sha256", "bytes"]))
        |> Enum.sort_by(& &1["path"])

      {:ok, files}
    end
  end

  defp index_declarations(declarations) do
    Enum.reduce_while(declarations, {:ok, %{}}, fn declaration, {:ok, indexed} ->
      with :ok <- validate_declaration(declaration),
           {:ok, path} <- validate_path(declaration["path"]),
           false <- path == "manifest.json",
           false <- Map.has_key?(indexed, String.downcase(path)) do
        declaration = Map.put(declaration, "path", path)
        {:cont, {:ok, Map.put(indexed, String.downcase(path), declaration)}}
      else
        true -> {:halt, {:error, :duplicate_or_reserved_manifest_path}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_declaration(declaration) when is_map(declaration) do
    valid? =
      non_empty_string?(declaration["path"]) and
        non_empty_string?(declaration["kind"]) and
        non_empty_string?(declaration["media_type"]) and
        valid_sha256?(declaration["sha256"]) and
        is_integer(declaration["bytes"]) and declaration["bytes"] >= 0 and
        declaration["contains_secrets"] == false and
        non_empty_string?(declaration["classification"])

    if valid?, do: :ok, else: {:error, :invalid_file_declaration}
  end

  defp validate_declaration(_declaration), do: {:error, :invalid_file_declaration}

  defp equal_file_sets(declared, archived) do
    archived = archived |> Enum.map(&String.downcase/1) |> MapSet.new()

    if MapSet.equal?(declared, archived) do
      :ok
    else
      {:error,
       {:manifest_file_set_mismatch,
        %{
          missing: MapSet.difference(declared, archived),
          undeclared: MapSet.difference(archived, declared)
        }}}
    end
  end

  defp verify_declared_files(declared, extracted) do
    extracted_by_lower = Map.new(extracted, fn {path, body} -> {String.downcase(path), body} end)

    Enum.reduce_while(declared, :ok, fn {path, declaration}, :ok ->
      body = Map.fetch!(extracted_by_lower, path)
      sha256 = sha256(body)

      cond do
        byte_size(body) != declaration["bytes"] ->
          {:halt, {:error, {:file_size_mismatch, declaration["path"]}}}

        sha256 != declaration["sha256"] ->
          {:halt, {:error, {:file_checksum_mismatch, declaration["path"]}}}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp file_sha256(path) do
    digest =
      path
      |> File.stream!(64 * 1024, [])
      |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()
      |> Base.encode16(case: :lower)

    {:ok, digest}
  rescue
    error -> {:error, {:hash_failed, Exception.message(error)}}
  end

  defp sha256(body), do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
  defp valid_sha256?(value), do: is_binary(value) and Regex.match?(~r/^[0-9a-f]{64}$/, value)
  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp valid_timestamp?(value) when is_binary(value) do
    match?({:ok, _datetime, _offset}, DateTime.from_iso8601(value))
  end

  defp valid_timestamp?(_value), do: false
end
