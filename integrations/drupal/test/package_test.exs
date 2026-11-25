defmodule Contexla.Integrations.Drupal.Test.PackageTest do
  use ExUnit.Case

  alias Contexla.Integrations.Drupal.AssessmentSnapshotAdapter

  test "exposes the bundled Drupal Integration definition" do
    assert {:ok, definition} =
             Contexla.Integrations.Sdk.Validator.validate_module(
               Contexla.Integrations.Drupal.Package
             )

    assert definition.id == "com.contexla.integration.drupal"

    assert [adapter] = definition.adapters
    assert adapter.contract == "contexla.estate.source.v1"
    assert adapter.source_types == ["contexla.drupal-snapshot.v1"]
  end

  test "validates a Drupal snapshot and returns provenance metadata" do
    path = snapshot_fixture!()

    assert {:ok, validation} = AssessmentSnapshotAdapter.validate_source(path, [])
    assert validation.source_type == "contexla.drupal-snapshot.v1"
    assert validation.manifest["package_id"] == "college-drupal-production"
    assert [%{"path" => "sources/drupal-status.json"}] = validation.files
    assert byte_size(validation.sha256) == 64
  end

  test "normalizes validated Drupal evidence into resources and relationships" do
    path = snapshot_fixture!()

    assert {:ok, normalized} = AssessmentSnapshotAdapter.normalize_source(path)
    assert normalized.target_key == "college-public-web"
    assert [%{kind: "cms", external_key: "college-public-web"}] = normalized.resources
    assert [%{path: "sources/drupal-status.json"}] = normalized.evidence
    assert normalized.relationships == []
    assert normalized.documents["sources/drupal-status.json"]["environment"] == "production"
  end

  test "normalizes aggregate usage counts as evidence-backed resources" do
    collected_at = "2026-11-19T15:00:00Z"

    validated = %{
      manifest: %{
        "created_at" => collected_at,
        "source" => %{"installation_id" => "college-public-web"},
        "collection" => %{"limitations" => []}
      },
      documents: %{
        "sources/drupal-status.json" => %{"name" => "College"},
        "sources/content-counts.json" => [
          %{"bundle" => "program", "label" => "Program", "count" => 4}
        ],
        "sources/media-counts.json" => [
          %{"bundle" => "document", "label" => "Document", "count" => 12}
        ]
      },
      files: [
        %{
          "path" => "sources/content-counts.json",
          "kind" => "drupal.content_counts",
          "media_type" => "application/json",
          "sha256" => String.duplicate("a", 64),
          "bytes" => 1
        },
        %{
          "path" => "sources/media-counts.json",
          "kind" => "drupal.media_counts",
          "media_type" => "application/json",
          "sha256" => String.duplicate("b", 64),
          "bytes" => 1
        }
      ]
    }

    assert {:ok, normalized} =
             Contexla.Integrations.Drupal.AssessmentSnapshotNormalizer.normalize(validated)

    assert Enum.any?(normalized.resources, fn resource ->
             resource.kind == "content_count" and resource.external_key == "program" and
               resource.attributes["count"] == 4 and
               resource.evidence_path == "sources/content-counts.json"
           end)

    assert Enum.any?(normalized.resources, fn resource ->
             resource.kind == "media_count" and resource.external_key == "document" and
               resource.attributes["count"] == 12 and
               resource.evidence_path == "sources/media-counts.json"
           end)
  end

  test "rejects a declared file whose checksum does not match" do
    path = snapshot_fixture!(declaration: &Map.put(&1, "sha256", String.duplicate("0", 64)))

    assert {:error, {:file_checksum_mismatch, "sources/drupal-status.json"}} =
             AssessmentSnapshotAdapter.validate_source(path, [])
  end

  test "rejects parent traversal paths before extraction" do
    path = snapshot_fixture!(extra_files: [{"../escape.txt", "unsafe"}])

    assert {:error, {:unsafe_zip_path, "../escape.txt"}} =
             AssessmentSnapshotAdapter.validate_source(path, [])
  end

  test "rejects files not declared by the manifest" do
    path = snapshot_fixture!(extra_files: [{"sources/undeclared.json", "{}"}])

    assert {:error, {:manifest_file_set_mismatch, mismatch}} =
             AssessmentSnapshotAdapter.validate_source(path, [])

    assert MapSet.member?(mismatch.undeclared, "sources/undeclared.json")
  end

  test "enforces configured archive limits" do
    path = snapshot_fixture!()

    assert {:error, {:limit_exceeded, :file_count, _actual, 0}} =
             AssessmentSnapshotAdapter.validate_source(path, limits: [file_count: 0])
  end

  defp snapshot_fixture!(opts \\ []) do
    File.mkdir_p!(".tmp")
    path = Path.expand(".tmp/snapshot-#{System.unique_integer([:positive])}.zip")
    on_exit(fn -> File.rm(path) end)

    source_body = Jason.encode!(%{"drupal_version" => "test", "environment" => "production"})

    declaration = %{
      "path" => "sources/drupal-status.json",
      "kind" => "drupal.system",
      "media_type" => "application/json",
      "sha256" => sha256(source_body),
      "bytes" => byte_size(source_body),
      "contains_secrets" => false,
      "classification" => "customer-confidential"
    }

    declaration = Keyword.get(opts, :declaration, & &1).(declaration)

    manifest = %{
      "contract" => "contexla.estate-evidence-package",
      "version" => "1.0",
      "profile" => %{"id" => "contexla.drupal-snapshot", "version" => "1.0"},
      "package_id" => "college-drupal-production",
      "created_at" => "2026-11-19T15:00:00Z",
      "producer" => %{"type" => "test", "name" => "fixture", "version" => "1"},
      "source" => %{
        "system" => "drupal",
        "installation_id" => "college-public-web",
        "environments" => ["production"]
      },
      "collection" => %{"mode" => "customer_export", "limitations" => []},
      "classification" => "customer-confidential",
      "files" => [declaration]
    }

    files =
      [
        {"manifest.json", Jason.encode!(manifest)},
        {"sources/drupal-status.json", source_body}
      ] ++ Keyword.get(opts, :extra_files, [])

    zip_entries = Enum.map(files, fn {name, body} -> {String.to_charlist(name), body} end)
    {:ok, {_name, archive}} = :zip.create(~c"snapshot.zip", zip_entries, [:memory])
    File.write!(path, archive)
    path
  end

  defp sha256(body), do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
end
