defmodule Contexla.Drupal.AssessmentSnapshotNormalizer do
  @moduledoc "Maps Drupal snapshot documents into the Estate Adapter contract."

  @adapter_id "drupal.assessment.snapshot.v1"
  @adapter_version "0.1.0"

  @document_kinds %{
    "modules.json" => "module",
    "themes.json" => "theme",
    "sites.json" => "site",
    "content-types.json" => "content_type",
    "fields.json" => "field",
    "views.json" => "view",
    "workflows.json" => "workflow",
    "roles-summary.json" => "role",
    "content-counts.json" => "content_count",
    "media-counts.json" => "media_count",
    "cron.json" => "scheduled_job"
  }

  def normalize(validated) do
    manifest = validated.manifest
    target_key = get_in(manifest, ["source", "installation_id"])
    status_path = find_path(validated.documents, "drupal-status.json")
    status = if status_path, do: Map.get(validated.documents, status_path, %{}), else: %{}

    root = %{
      kind: "cms",
      external_key: target_key,
      name: status["name"] || target_key,
      attributes: status,
      evidence_path: status_path
    }

    resources = [root | document_resources(validated.documents)]

    relationships =
      resources
      |> Enum.reject(&(&1.external_key == root.external_key and &1.kind == "cms"))
      |> Enum.map(fn resource ->
        %{
          from: {root.kind, root.external_key},
          to: {resource.kind, resource.external_key},
          kind: "contains",
          attributes: %{},
          evidence_path: resource.evidence_path
        }
      end)

    {:ok,
     %{
       adapter_id: @adapter_id,
       adapter_version: @adapter_version,
       target_key: target_key,
       collected_at: parse_datetime(manifest["created_at"]),
       limitations: get_in(manifest, ["collection", "limitations"]) || [],
       evidence: Enum.map(validated.files, &evidence/1),
       resources: resources,
       relationships: relationships,
       documents: validated.documents
     }}
  end

  defp document_resources(documents) do
    Enum.flat_map(documents, fn {path, document} ->
      case Map.get(@document_kinds, Path.basename(path)) do
        nil -> []
        kind -> normalize_records(document, kind, path)
      end
    end)
  end

  defp normalize_records(document, kind, path) do
    document
    |> records(kind)
    |> Enum.with_index()
    |> Enum.map(fn {record, index} ->
      key = identity(record, index)

      %{
        kind: kind,
        external_key: key,
        name: record["label"] || record["name"] || record["machine_name"] || key,
        attributes: record,
        evidence_path: path
      }
    end)
  end

  defp records(value, _kind) when is_list(value), do: Enum.filter(value, &is_map/1)

  defp records(value, kind) when is_map(value) do
    plural = String.replace(kind, "_", "-") <> "s"
    underscore_plural = kind <> "s"
    candidate = value[plural] || value[underscore_plural] || value["items"]

    cond do
      is_list(candidate) ->
        Enum.filter(candidate, &is_map/1)

      Enum.all?(value, fn {_key, item} -> is_map(item) end) ->
        Enum.map(value, fn {key, item} -> Map.put_new(item, "id", key) end)

      true ->
        []
    end
  end

  defp records(_value, _kind), do: []

  defp identity(record, index) do
    Enum.find_value(["id", "machine_name", "name", "type", "bundle", "uuid"], fn key ->
      value = record[key]
      if is_binary(value) and String.trim(value) != "", do: value
    end) || "item-#{index + 1}"
  end

  defp evidence(file) do
    %{
      path: file["path"],
      kind: file["kind"],
      media_type: file["media_type"],
      sha256: file["sha256"],
      byte_size: file["bytes"],
      metadata: %{}
    }
  end

  defp find_path(documents, basename) do
    Enum.find(Map.keys(documents), &(Path.basename(&1) == basename))
  end

  defp parse_datetime(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    DateTime.truncate(datetime, :second)
  end
end
