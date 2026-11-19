defmodule Contexla.DrupalSnapshotFixtures do
  @moduledoc false

  def snapshot_fixture!(opts \\ []) do
    directory = Path.expand(".tmp/test-uploads")
    File.mkdir_p!(directory)
    path = Path.join(directory, "snapshot-#{System.unique_integer([:positive])}.zip")

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

    files = [
      {"manifest.json", Jason.encode!(manifest)},
      {"sources/drupal-status.json", source_body}
    ]

    zip_entries = Enum.map(files, fn {name, body} -> {String.to_charlist(name), body} end)
    {:ok, {_name, archive}} = :zip.create(~c"snapshot.zip", zip_entries, [:memory])
    File.write!(path, archive)
    path
  end

  defp sha256(body), do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
end
