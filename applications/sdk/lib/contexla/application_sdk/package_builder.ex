defmodule Contexla.ApplicationSDK.PackageBuilder do
  @moduledoc "Builds deterministic trusted Application package archives."

  @manifest "contexla-application.json"

  alias Contexla.ApplicationSDK

  def build(manifest_path, app_path, output_path) do
    with {:ok, manifest_bytes} <- File.read(manifest_path),
         {:ok, manifest} <- Jason.decode(manifest_bytes),
         :ok <- validate_manifest(manifest),
         {:ok, definition} <- compiled_definition(manifest),
         :ok <- validate_definition_identity(manifest, definition),
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
         "manifestVersion" => 1,
         "applicationId" => id,
         "name" => name,
         "icon" => icon,
         "version" => version,
         "otpApplication" => application,
         "entryModule" => entry_module,
         "sdkRequirement" => sdk_requirement,
         "operations" => operations,
         "surfaces" => surfaces
       })
       when is_binary(id) and is_binary(name) and is_binary(version) and
              is_binary(application) and is_binary(entry_module) and is_binary(icon) and
              is_binary(sdk_requirement) and is_list(operations) and is_list(surfaces) do
    valid_surfaces? = Enum.all?(surfaces, &valid_surface?/1)

    default_instances =
      Enum.count(surfaces, fn surface ->
        is_map(surface) and surface["role"] == "instance" and surface["default"] == true
      end)

    new_surfaces = Enum.count(surfaces, &(is_map(&1) and &1["role"] == "new"))

    settings_surfaces =
      Enum.count(surfaces, fn surface ->
        is_map(surface) and surface["role"] == "instance" and surface["kind"] == "settings"
      end)

    ids = Enum.map(surfaces, fn surface -> is_map(surface) && surface["id"] end)
    paths = Enum.map(surfaces, fn surface -> is_map(surface) && surface["path"] end)

    if String.trim(id) != "" and String.trim(name) != "" and
         Version.match?(sdk_version(), sdk_requirement) and
         Enum.all?(operations, &(is_binary(&1) and String.trim(&1) != "")) and
         icon =~ ~r/^hero-[a-z0-9-]+$/ and valid_surfaces? and default_instances == 1 and
         new_surfaces == 1 and settings_surfaces == 1 and Enum.uniq(ids) == ids and
         Enum.uniq(paths) == paths,
       do: :ok,
       else: {:error, :invalid_manifest}
  rescue
    Version.InvalidRequirementError -> {:error, :invalid_manifest}
  end

  defp validate_manifest(_manifest), do: {:error, :invalid_manifest}

  defp compiled_definition(manifest) do
    manifest["entryModule"]
    |> then(&Module.concat([&1]))
    |> ApplicationSDK.validate_module()
  end

  defp validate_definition_identity(manifest, definition) do
    checks = [
      {:application_id, manifest["applicationId"], definition.id},
      {:name, manifest["name"], definition.name},
      {:icon, manifest["icon"], definition.icon},
      {:version, manifest["version"], definition.version},
      {:otp_application, manifest["otpApplication"], Atom.to_string(definition.otp_application)},
      {:entry_module, manifest["entryModule"], module_name(definition.entry_module)},
      {:database_schema, manifest["databaseSchema"], definition.database_schema},
      {:operations, Enum.sort(manifest["operations"]), operation_ids(definition)},
      {:surfaces, manifest_surfaces(manifest), definition_surfaces(definition)}
    ]

    case Enum.find(checks, fn {_field, declared, compiled} -> declared != compiled end) do
      nil ->
        :ok

      {field, declared, compiled} ->
        {:error, {:manifest_definition_mismatch, field, declared, compiled}}
    end
  end

  defp operation_ids(definition),
    do: definition.operations |> Enum.map(& &1.id) |> Enum.sort()

  defp manifest_surfaces(manifest) do
    manifest["surfaces"]
    |> Enum.map(fn surface ->
      %{
        id: surface["id"],
        path: surface["path"],
        module: surface["module"],
        role: surface["role"],
        default: Map.get(surface, "default", false),
        kind: Map.get(surface, "kind", "page")
      }
    end)
    |> Enum.sort_by(& &1.id)
  end

  defp definition_surfaces(definition) do
    definition.surfaces
    |> Enum.map(fn surface ->
      %{
        id: Atom.to_string(surface.id),
        path: surface.path,
        module: module_name(surface.module),
        role: Atom.to_string(surface.role),
        default: surface.default,
        kind: Atom.to_string(surface.kind)
      }
    end)
    |> Enum.sort_by(& &1.id)
  end

  defp module_name(module), do: module |> Module.split() |> Enum.join(".")

  defp sdk_version do
    :contexla_application_sdk
    |> Application.spec(:vsn)
    |> to_string()
  end

  defp valid_surface?(surface) when is_map(surface) do
    is_binary(surface["id"]) and surface["id"] != "" and
      is_binary(surface["path"]) and surface["path"] != "" and
      not String.contains?(surface["path"], ["/", "..", "\\"]) and
      is_binary(surface["module"]) and surface["module"] != "" and
      surface["role"] in ["new", "instance"] and
      (not Map.has_key?(surface, "kind") or surface["kind"] in ["page", "settings"]) and
      (not Map.has_key?(surface, "default") or is_boolean(surface["default"])) and
      (surface["default"] != true or surface["role"] == "instance") and
      (surface["default"] != true or surface["kind"] != "settings")
  end

  defp valid_surface?(_surface), do: false

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
