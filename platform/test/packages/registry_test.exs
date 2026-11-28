defmodule Contexla.Platform.Test.Packages.RegistryTest do
  use ExUnit.Case, async: true

  alias Contexla.Platform.Packages.Registry

  setup_all do
    if Process.whereis(Registry) do
      :ok
    else
      start_supervised!(Registry)
      :ok
    end
  end

  test "registers an Application through its SDK definition" do
    assert [application] = Registry.applications()
    assert application.id == "com.contexla.test.application"

    assert {:ok, ^application} = Registry.fetch_application(application.id)

    assert [{Contexla.Platform.Test.Support.PackageFixtures.TestApplication, ^application}] =
             Registry.application_entries()
  end

  test "registers an Integration through its SDK definition" do
    assert [integration] = Registry.integrations()
    assert integration.id == "com.contexla.test.integration"

    assert {:ok, ^integration} = Registry.fetch_integration(integration.id)

    assert {:ok, {^integration, adapter}} =
             Registry.fetch_adapter("test.snapshot.v1")

    assert adapter.contract == "contexla.test.source.v1"
  end

  test "returns not found for unknown package identities" do
    assert {:error, :not_found} = Registry.fetch_application("missing")
    assert {:error, :not_found} = Registry.fetch_integration("missing")
  end

  describe "node role" do
    setup do
      original = Application.get_env(:contexla, :node_role)
      on_exit(fn -> Application.put_env(:contexla, :node_role, original) end)
      :ok
    end

    test "defaults to :all when node_role is not configured" do
      Application.delete_env(:contexla, :node_role)
      assert Application.get_env(:contexla, :node_role, :all) == :all
    end

    test "registry loads applications regardless of node_role" do
      for role <- [:all, :web, :worker] do
        Application.put_env(:contexla, :node_role, role)
        assert [_] = Registry.applications()
      end
    end
  end
end
