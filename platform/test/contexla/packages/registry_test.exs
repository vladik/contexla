defmodule Contexla.Packages.RegistryTest do
  use ExUnit.Case, async: true

  alias Contexla.Packages.Registry

  setup_all do
    if Process.whereis(Registry) do
      :ok
    else
      start_supervised!(Registry)
      :ok
    end
  end

  test "registers the bundled Application" do
    assert [application] = Registry.applications()
    assert application.id == "com.contexla.application.digital-estate-assessment"

    assert {:ok, ^application} = Registry.fetch_application(application.id)
  end

  test "registers the bundled Drupal Integration" do
    assert [integration] = Registry.integrations()
    assert integration.id == "com.contexla.integration.drupal"

    assert {:ok, ^integration} = Registry.fetch_integration(integration.id)

    assert {:ok, {^integration, adapter}} =
             Registry.fetch_adapter("drupal.assessment.snapshot.v1")

    assert adapter.contract == "contexla.estate.source.v1"
  end

  test "returns not found for unknown package identities" do
    assert {:error, :not_found} = Registry.fetch_application("missing")
    assert {:error, :not_found} = Registry.fetch_integration("missing")
  end
end
