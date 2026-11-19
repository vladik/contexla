defmodule Contexla.ApplicationSDKTest do
  use ExUnit.Case

  alias Contexla.ApplicationSDK
  alias Contexla.ApplicationSDK.Definition
  alias Contexla.ApplicationSDK.Operation

  defmodule ValidApplication do
    @behaviour Contexla.ApplicationSDK.Application

    @operation %Operation{id: "example.run", name: "Run example"}

    @impl true
    def definition do
      %Definition{
        id: "com.contexla.test.example",
        name: "Example",
        version: "1.0.0",
        otp_application: :example,
        entry_module: __MODULE__,
        operations: available_operations(),
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
end
