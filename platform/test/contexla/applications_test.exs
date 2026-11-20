defmodule Contexla.ApplicationsTest do
  use Contexla.DataCase, async: true

  alias Contexla.Applications
  alias Contexla.Applications.ApplicationInstance

  import Contexla.AccountsFixtures

  setup do
    %{scope: user_scope_fixture()}
  end

  test "lists an installed Application without compiling against it", %{scope: scope} do
    assert [definition] = Applications.list_installed_applications(scope)
    assert definition.id == "com.contexla.test.application"
  end

  test "creates and version-pins a validated Application Instance", %{scope: scope} do
    attrs = %{
      "application_id" => "com.contexla.test.application",
      "name" => "Configured Test Instance",
      "config" => %{"profile" => "test"}
    }

    assert {:ok, %ApplicationInstance{} = instance} =
             Applications.create_instance(scope, attrs)

    assert instance.name == "Configured Test Instance"
    assert instance.application_version == "1.0.0"
    assert instance.status == :draft
    assert instance.created_by_user_id == scope.user.id
    assert [^instance] = Applications.list_instances(scope)
  end

  test "rejects invalid Application configuration", %{scope: scope} do
    assert {:error, {:invalid_instance_config, :must_be_a_map}} =
             Applications.create_instance(scope, %{
               "application_id" => "com.contexla.test.application",
               "name" => "Invalid",
               "config" => "invalid"
             })
  end

  test "rejects an uninstalled Application identity", %{scope: scope} do
    assert {:error, :application_not_installed} =
             Applications.create_instance(scope, %{
               "application_id" => "com.example.missing",
               "name" => "Missing",
               "config" => %{}
             })
  end

  test "updates Instance identity and uses an icon override in navigation", %{scope: scope} do
    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Original",
        "config" => %{}
      })

    assert {:ok, updated} =
             Applications.update_instance_settings(scope, instance.id, %{
               "name" => "Renamed",
               "description" => "The primary assessment estate",
               "icon" => "hero-rocket-launch"
             })

    assert updated.name == "Renamed"
    assert updated.description == "The primary assessment estate"
    assert updated.icon == "hero-rocket-launch"

    assert [
             %{
               name: "Renamed",
               description: "The primary assessment estate",
               icon: "hero-rocket-launch"
             }
           ] =
             Applications.list_navigation_instances(scope)
  end

  test "validates Application-owned configuration before updating it", %{scope: scope} do
    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Configurable",
        "config" => %{}
      })

    assert {:ok, updated} =
             Applications.update_instance_config(scope, instance.id, %{"profile" => "updated"})

    assert updated.config == %{"profile" => "updated"}
  end
end
