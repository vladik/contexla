defmodule Contexla.Platform.Test.ToolsTest do
  use Contexla.Platform.Test.Support.DataCase, async: false

  alias Contexla.Platform.Applications
  alias Contexla.Platform.Tools
  alias Contexla.Platform.Tools.{Catalog, Invocation, Tool}

  import Contexla.Platform.Test.Support.Fixtures.AccountsFixtures

  setup do
    scope = user_scope_fixture()

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Tool Test Instance",
        "config" => %{"profile" => "dependency-test"}
      })

    %{scope: scope, instance: instance}
  end

  test "synchronizes immutable bundled Tool definitions" do
    assert :ok = Catalog.sync_bundled()

    assert %Tool{
             key: "com.contexla.dependencies.parse-composer",
             version: "2.0.0",
             runtime: :native,
             status: :active
           } = Repo.get_by!(Tool, key: "com.contexla.dependencies.parse-composer")

    assert Repo.aggregate(Tool, :count) == 3

    assert :ok = Catalog.sync_bundled()
  end

  test "requests and executes a Tool while retaining bounded provenance", %{
    scope: scope,
    instance: instance
  } do
    input = %{
      "composer_json" => %{"require" => %{"vendor/core" => "^10"}},
      "composer_lock" => %{
        "packages" => [
          %{"name" => "vendor/core", "version" => "10.4.0", "type" => "library"}
        ]
      }
    }

    assert {:ok, %Invocation{status: :pending} = requested} =
             Tools.request(
               scope,
               instance,
               "com.contexla.dependencies.parse-composer",
               "2.0.0",
               input,
               parent_run_id: Ecto.UUID.generate()
             )

    assert requested.input == %{
             "composer_json" => "[REDACTED]",
             "composer_lock" => "[REDACTED]"
           }

    assert requested.input_artifact_id
    assert :ok = Tools.execute(requested.id, final_attempt?: true)

    invocation = Repo.get!(Invocation, requested.id)
    assert invocation.status == :succeeded
    assert invocation.application_instance_id == instance.id
    assert invocation.invoked_by_user_id == scope.user.id

    assert %{"dependencies" => [dependency]} = invocation.output

    assert dependency == %{
             "name" => "vendor/core",
             "version" => "10.4.0",
             "type" => "library",
             "development" => false,
             "direct" => true
           }
  end

  test "rejects input that does not satisfy the Tool contract", %{
    scope: scope,
    instance: instance
  } do
    assert {:error, %{path: "$", missing: ["composer_lock"]}} =
             Tools.request(
               scope,
               instance,
               "com.contexla.dependencies.parse-composer",
               "2.0.0",
               %{"composer_json" => %{}}
             )

    refute Repo.exists?(Invocation)
  end
end
