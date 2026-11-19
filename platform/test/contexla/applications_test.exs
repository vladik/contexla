defmodule Contexla.ApplicationsTest do
  use Contexla.DataCase, async: true

  alias Contexla.Applications
  alias Contexla.Applications.ApplicationInstance

  import Contexla.AccountsFixtures

  setup do
    %{scope: user_scope_fixture()}
  end

  test "lists the bundled Digital Estate Assessment Application", %{scope: scope} do
    assert [definition] = Applications.list_installed_applications(scope)
    assert definition.id == "com.contexla.application.digital-estate-assessment"
  end

  test "creates and version-pins a validated Application Instance", %{scope: scope} do
    attrs = %{
      "application_id" => "com.contexla.application.digital-estate-assessment",
      "name" => "College Drupal Estate",
      "config" => %{
        "decision" => "Assess modernization readiness",
        "scope" => %{"cms" => "drupal"}
      }
    }

    assert {:ok, %ApplicationInstance{} = instance} =
             Applications.create_instance(scope, attrs)

    assert instance.name == "College Drupal Estate"
    assert instance.application_version == "0.1.0"
    assert instance.status == :draft
    assert instance.created_by_user_id == scope.user.id
    assert [^instance] = Applications.list_instances(scope)
  end

  test "rejects invalid Application configuration", %{scope: scope} do
    assert {:error, {:invalid_instance_config, {:invalid_config, _message}}} =
             Applications.create_instance(scope, %{
               "application_id" => "com.contexla.application.digital-estate-assessment",
               "name" => "Invalid",
               "config" => %{}
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
end
