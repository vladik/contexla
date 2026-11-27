defmodule Contexla.Applications.Sdk.PackageBuilder do
  @moduledoc "Builds deterministic trusted Application package archives."

  @manifest "contexla-application.json"
  @manifest_version 2

  alias Contexla.Applications.Sdk.Validator, as: ApplicationSDK

  def build(manifest_path, app_path, output_path) do
    with {:ok, manifest_bytes} <- File.read(manifest_path),
         {:ok, manifest} <- Jason.decode(manifest_bytes),
         :ok <- validate_manifest(manifest),
         {:ok, definition} <- compiled_definition(manifest),
         :ok <- validate_entry_module(manifest, definition),
         {:ok, app_files} <- collect_app_files(app_path, manifest),
         files <- [{@manifest, manifest_bytes} | app_files] |> Enum.sort_by(&elem(&1, 0)),
         checksums <- checksums(files),
         archive <- zip(files ++ [{"CHECKSUMS", checksums}]),
         :ok <- File.mkdir_p(Path.dirname(output_path)),
         :ok <- File.write(output_path, archive) do
      {:ok,
       %{
         path: Path.expand(output_path),
         digest: sha256(archive),
         files: length(files) + 1,
         manifest: manifest
       }}
    end
  end

  defp validate_manifest(%{
         "manifestVersion" => @manifest_version,
         "applicationId" => id,
         "name" => name,
         "icon" => icon,
         "version" => version,
         "otpApplication" => application,
         "entryModule" => entry_module,
         "sdkRequirement" => sdk_requirement,
         "surfaces" => surfaces,
         "operations" => operations
       } = manifest)
       when is_binary(id) and is_binary(name) and is_binary(version) and
              is_binary(application) and is_binary(entry_module) and is_binary(icon) and
              is_binary(sdk_requirement) and is_list(surfaces) and is_list(operations) do
    queues = Map.get(manifest, "queues", [])

    with true <- String.trim(id) != "",
         true <- String.trim(name) != "",
         true <- Version.match?(sdk_version(), sdk_requirement),
         true <- icon =~ ~r/^hero-[a-z0-9-]+$/,
         true <- Enum.all?(operations, &valid_operation?/1),
         true <- Enum.all?(surfaces, &valid_surface?/1),
         true <- Enum.all?(queues, &valid_queue?/1),
         true <- unique_ids?(operations, "id"),
         true <- unique_ids?(surfaces, "id"),
         true <- unique_ids?(surfaces, "path"),
         true <- surface_roles_valid?(surfaces) do
      :ok
    else
      _ -> {:error, :invalid_manifest}
    end
  rescue
    Version.InvalidRequirementError -> {:error, :invalid_manifest}
  end

  defp validate_manifest(%{"manifestVersion" => v}) when v != @manifest_version,
    do: {:error, {:unsupported_manifest_version, v}}

  defp validate_manifest(_manifest), do: {:error, :invalid_manifest}

  defp valid_operation?(op) when is_map(op) do
    is_binary(op["id"]) and op["id"] != "" and
      (not Map.has_key?(op, "name") or is_binary(op["name"])) and
      (not Map.has_key?(op, "queue") or is_binary(op["queue"])) and
      (not Map.has_key?(op, "maxAttempts") or
         (is_integer(op["maxAttempts"]) and op["maxAttempts"] > 0)) and
      (not Map.has_key?(op, "timeoutSeconds") or
         (is_integer(op["timeoutSeconds"]) and op["timeoutSeconds"] > 0)) and
      (not Map.has_key?(op, "requiresApproval") or is_boolean(op["requiresApproval"])) and
      (not Map.has_key?(op, "inputSchema") or is_map(op["inputSchema"])) and
      (not Map.has_key?(op, "requiredTools") or valid_required_tools?(op["requiredTools"])) and
      (not Map.has_key?(op, "kind") or op["kind"] in ["command", "read"])
  end

  defp valid_operation?(_), do: false

  defp valid_required_tools?(tools) when is_list(tools),
    do: Enum.all?(tools, &(is_map(&1) and is_binary(&1["toolId"]) and is_binary(&1["version"])))

  defp valid_required_tools?(_), do: false

  defp valid_surface?(surface) when is_map(surface) do
    is_binary(surface["id"]) and surface["id"] != "" and
      is_binary(surface["path"]) and surface["path"] != "" and
      not String.contains?(surface["path"], ["/", "..", "\\"]) and
      is_binary(surface["module"]) and surface["module"] != "" and
      surface["role"] in ["new", "instance"] and
      (not Map.has_key?(surface, "label") or is_binary(surface["label"])) and
      (not Map.has_key?(surface, "kind") or surface["kind"] in ["page", "settings"]) and
      (not Map.has_key?(surface, "default") or is_boolean(surface["default"])) and
      (surface["default"] != true or surface["role"] == "instance") and
      (surface["default"] != true or Map.get(surface, "kind", "page") != "settings")
  end

  defp valid_surface?(_), do: false

  defp valid_queue?(q) when is_map(q),
    do: is_binary(q["name"]) and q["name"] != "" and is_integer(q["concurrency"]) and q["concurrency"] > 0

  defp valid_queue?(_), do: false

  defp unique_ids?(items, key) do
    ids = Enum.map(items, &(is_map(&1) && &1[key]))
    Enum.uniq(ids) == ids
  end

  defp surface_roles_valid?(surfaces) do
    default_instances = Enum.count(surfaces, &(is_map(&1) and &1["role"] == "instance" and &1["default"] == true))
    new_surfaces = Enum.count(surfaces, &(is_map(&1) and &1["role"] == "new"))
    settings_surfaces = Enum.count(surfaces, &(is_map(&1) and &1["role"] == "instance" and Map.get(&1, "kind") == "settings"))
    default_instances == 1 and new_surfaces == 1 and settings_surfaces == 1
  end

  defp compiled_definition(manifest) do
    manifest["entryModule"]
    |> then(&Module.concat([&1]))
    |> ApplicationSDK.validate_module()
  end

  defp validate_entry_module(manifest, definition) do
    declared = manifest["entryModule"]
    compiled = definition.entry_module |> Module.split() |> Enum.join(".")

    if declared == compiled,
      do: :ok,
      else: {:error, {:manifest_definition_mismatch, :entry_module, declared, compiled}}
  end

  defp collect_app_files(app_path, manifest) do
    application = manifest["otpApplication"]
    version = manifest["version"]
    prefix = "lib/#{application}-#{version}"

    files =
      [Path.join(app_path, "ebin"), Path.join(app_path, "priv")]
      |> Enum.flat_map(&regular_files/1)
      |> Enum.sort()

    if files == [] do
      {:error, :compiled_application_not_found}
    else
      {:ok,
       Enum.map(files, fn source ->
         relative = source |> Path.relative_to(app_path) |> String.replace("\\", "/")
         {"#{prefix}/#{relative}", File.read!(source)}
       end)}
    end
  end

  defp regular_files(root) do
    case File.ls(root) do
      {:ok, names} ->
        Enum.flat_map(names, fn name ->
          path = Path.join(root, name)
          if File.dir?(path), do: regular_files(path), else: [path]
        end)

      {:error, :enoent} ->
        []
    end
  end

  defp checksums(files),
    do: Enum.map_join(files, "", fn {path, bytes} -> "#{sha256(bytes)}  #{path}\n" end)

  defp sha256(bytes),
    do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp sdk_version do
    :contexla_application_sdk
    |> Application.spec(:vsn)
    |> to_string()
  end

  defp zip(files) do
    {locals, central, offset} =
      Enum.reduce(files, {[], [], 0}, fn {name, data}, {locals, central, offset} ->
        name = :unicode.characters_to_binary(name)
        crc = :erlang.crc32(data)
        size = byte_size(data)

        local =
          <<0x04034B50::little-32, 20::little-16, 0x0800::little-16, 0::little-16, 0::little-16,
            0x21::little-16, crc::little-32, size::little-32, size::little-32,
            byte_size(name)::little-16, 0::little-16, name::binary, data::binary>>

        directory =
          <<0x02014B50::little-32, 20::little-16, 20::little-16, 0x0800::little-16, 0::little-16,
            0::little-16, 0x21::little-16, crc::little-32, size::little-32, size::little-32,
            byte_size(name)::little-16, 0::little-16, 0::little-16, 0::little-16, 0::little-16,
            0::little-32, offset::little-32, name::binary>>

        {[local | locals], [directory | central], offset + byte_size(local)}
      end)

    central = central |> Enum.reverse() |> IO.iodata_to_binary()
    count = length(files)

    end_record =
      <<0x06054B50::little-32, 0::little-16, 0::little-16, count::little-16, count::little-16,
        byte_size(central)::little-32, offset::little-32, 0::little-16>>

    IO.iodata_to_binary([Enum.reverse(locals), central, end_record])
  end
end
