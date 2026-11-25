defmodule Contexla.Applications.Sdk.Test.ValidatorTest do
  use ExUnit.Case

  alias Contexla.Applications.Sdk.Validator, as: ApplicationSDK
  alias Contexla.Applications.Sdk.Definition
  alias Contexla.Applications.Sdk.{Operation, Surface}

  defmodule ValidApplication do
    @behaviour Contexla.Applications.Sdk.Application

    @operation %Operation{id: "example.run", name: "Run example"}

    @impl true
    def definition do
      %Definition{
        id: "com.contexla.test.example",
        name: "Example",
        icon: "hero-beaker",
        version: "1.0.0",
        otp_application: :example,
        entry_module: __MODULE__,
        operations: available_operations(),
        surfaces: [
          %Surface{id: :new, path: "new", module: __MODULE__, role: :new},
          %Surface{
            id: :home,
            path: "home",
            module: __MODULE__,
            role: :instance,
            default: true
          },
          %Surface{
            id: :settings,
            path: "settings",
            module: __MODULE__,
            role: :instance,
            kind: :settings
          }
        ],
        required_adapter_contracts: required_adapter_contracts()
      }
    end

    @impl true
    def validate_instance_config(config), do: {:ok, config}

    @impl true
    def available_operations, do: [@operation]

    @impl true
    def required_adapter_contracts, do: ["example.source.v1"]
  end

  test "validates an Application module and returns its definition" do
    assert {:ok, definition} = ApplicationSDK.validate_module(ValidApplication)
    assert definition.id == "com.contexla.test.example"
    assert [%Operation{id: "example.run"}] = definition.operations
  end

  test "rejects a module that does not implement the contract" do
    assert {:error, {:missing_callbacks, missing}} =
             ApplicationSDK.validate_module(__MODULE__)

    assert {:definition, 0} in missing
  end

  test "requires one default Instance surface" do
    definition = ValidApplication.definition()
    surfaces = Enum.map(definition.surfaces, &%{&1 | default: false})

    assert {:error, :one_default_instance_surface_required} =
             Definition.validate(%{definition | surfaces: surfaces})
  end

  test "rejects duplicate Operation identities" do
    definition = ValidApplication.definition()
    operation = hd(definition.operations)

    assert {:error, :duplicate_operation_id} =
             Definition.validate(%{definition | operations: [operation, operation]})
  end
end
