defmodule Contexla.CapabilitiesTest do
  use Contexla.DataCase, async: false

  alias Contexla.Applications
  alias Contexla.Capabilities
  alias Contexla.Capabilities.{Binding, Catalog, Contract, Invocation, Processor, Resolver}

  import Contexla.AccountsFixtures

  setup do
    scope = user_scope_fixture()

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Capability Test Instance",
        "config" => %{"profile" => "dependency-test"}
      })

    %{scope: scope, instance: instance}
  end

  test "synchronizes bundled contracts, Processors, and the default binding" do
    assert :ok = Catalog.sync_bundled()

    assert %Contract{key: "com.contexla.dependencies.parse-composer"} =
             contract =
             Repo.one!(Contract)

    assert %Processor{
             key: "com.contexla.processor.composer.native",
             runtime: :native,
             capability_id: capability_id
           } = processor = Repo.one!(Processor)

    assert capability_id == contract.id

    assert %Binding{scope: :platform, scope_key: "platform", processor_id: processor_id} =
             Repo.one!(Binding)

    assert processor_id == processor.id
    assert :ok = Catalog.sync_bundled()
  end

  test "invokes a Capability through its bound native Processor and records provenance", %{
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

    assert {:ok, %{"dependencies" => [dependency]}, %Invocation{} = invocation} =
             Capabilities.invoke(
               scope,
               instance,
               "com.contexla.dependencies.parse-composer",
               "2",
               input
             )

    assert dependency == %{
             "name" => "vendor/core",
             "version" => "10.4.0",
             "type" => "library",
             "development" => false,
             "direct" => true
           }

    assert invocation.status == :succeeded
    assert invocation.application_instance_id == instance.id
    assert invocation.invoked_by_user_id == scope.user.id
    assert invocation.capability_id
    assert invocation.processor_id
    assert invocation.binding_id

    assert invocation.input == %{
             "composer_json" => "[REDACTED]",
             "composer_lock" => "[REDACTED]"
           }

    assert invocation.output == %{"dependencies" => [dependency]}
  end

  test "prefers an Instance Binding over the Platform default", %{instance: instance} do
    assert :ok = Catalog.sync_bundled()
    contract = Repo.one!(Contract)
    processor = Repo.one!(Processor)

    instance_binding =
      %Binding{}
      |> Binding.changeset(%{
        capability_id: contract.id,
        processor_id: processor.id,
        scope: :instance,
        scope_key: instance.id,
        config: %{"profile" => "college"},
        granted_permissions: [],
        status: :active
      })
      |> Repo.insert!()

    assert {:ok, resolved, ^processor} = Resolver.resolve(contract, instance)
    assert resolved.id == instance_binding.id
  end

  test "rejects input that does not satisfy the Capability contract", %{
    scope: scope,
    instance: instance
  } do
    assert {:error, %{path: "$", missing: ["composer_lock"]}} =
             Capabilities.invoke(
               scope,
               instance,
               "com.contexla.dependencies.parse-composer",
               "2",
               %{"composer_json" => %{}}
             )

    refute Repo.exists?(Invocation)
  end
end
