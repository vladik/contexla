defmodule Contexla.SourceImportsTest do
  use Contexla.DataCase, async: true

  alias Contexla.Applications
  alias Contexla.Artifacts
  alias Contexla.Artifacts.Artifact
  alias Contexla.Repo
  alias Contexla.SourceImports

  import Contexla.AccountsFixtures
  import Contexla.DrupalSnapshotFixtures

  setup do
    scope = user_scope_fixture()

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.application.digital-estate-assessment",
        "name" => "College Drupal Estate #{System.unique_integer([:positive])}",
        "config" => %{
          "decision" => "Assess modernization readiness",
          "scope" => %{"cms" => "drupal"}
        }
      })

    %{scope: scope, instance: instance}
  end

  test "validates and stores a Drupal snapshot as an immutable Artifact", context do
    path = snapshot_fixture!()

    assert {:ok, artifact} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "drupal.assessment.snapshot.v1",
               path,
               filename: "college-drupal-snapshot.zip"
             )

    assert artifact.kind == "source_snapshot"
    assert artifact.source_type == "contexla.drupal-snapshot.v1"
    assert artifact.filename == "college-drupal-snapshot.zip"
    assert artifact.application_instance_id == context.instance.id
    assert artifact.metadata["adapter_id"] == "drupal.assessment.snapshot.v1"
    assert artifact.metadata["manifest"]["package_id"] == "college-drupal-production"
    assert File.exists?(Artifacts.local_path(artifact))
  end

  test "returns the existing Artifact when the same snapshot is imported again", context do
    path = snapshot_fixture!()

    assert {:ok, first} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "drupal.assessment.snapshot.v1",
               path
             )

    assert {:ok, second} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "drupal.assessment.snapshot.v1",
               path
             )

    assert first.id == second.id
    assert Repo.aggregate(Artifact, :count) == 1
  end

  test "does not persist an Artifact when snapshot validation fails", context do
    path =
      snapshot_fixture!(declaration: &Map.put(&1, "sha256", String.duplicate("0", 64)))

    assert {:error, {:file_checksum_mismatch, "sources/drupal-status.json"}} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "drupal.assessment.snapshot.v1",
               path
             )

    assert Repo.aggregate(Artifact, :count) == 0
  end

  test "rejects an Adapter that is not installed", context do
    path = snapshot_fixture!()

    assert {:error, :adapter_not_installed} =
             SourceImports.import(context.scope, context.instance.id, "missing.adapter", path)
  end
end
