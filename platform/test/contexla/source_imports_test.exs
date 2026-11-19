defmodule Contexla.SourceImportsTest do
  use Contexla.DataCase, async: true

  alias Contexla.{Applications, Artifacts, Repo, SourceImports}
  alias Contexla.Artifacts.Artifact

  import Contexla.AccountsFixtures

  setup do
    scope = user_scope_fixture()

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Generic Import #{System.unique_integer([:positive])}",
        "config" => %{}
      })

    path =
      Path.join(System.tmp_dir!(), "contexla-source-#{System.unique_integer([:positive])}.dat")

    File.write!(path, "bounded test evidence")
    on_exit(fn -> File.rm(path) end)

    %{scope: scope, instance: instance, path: path}
  end

  test "validates and stores source evidence through an installed Adapter", context do
    assert {:ok, artifact} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "test.snapshot.v1",
               context.path
             )

    assert artifact.application_instance_id == context.instance.id
    assert artifact.metadata["adapter_id"] == "test.snapshot.v1"
    assert File.exists?(Artifacts.local_path(artifact))
  end

  test "deduplicates immutable source evidence", context do
    assert {:ok, first} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "test.snapshot.v1",
               context.path
             )

    assert {:ok, second} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "test.snapshot.v1",
               context.path
             )

    assert first.id == second.id
    assert Repo.aggregate(Artifact, :count) == 1
  end

  test "rejects an Adapter that is not installed", context do
    assert {:error, :adapter_not_installed} =
             SourceImports.import(
               context.scope,
               context.instance.id,
               "missing.adapter",
               context.path
             )
  end
end
