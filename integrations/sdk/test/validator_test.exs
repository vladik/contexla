defmodule Contexla.Integrations.Sdk.Test.ValidatorTest do
  use ExUnit.Case

  alias Contexla.Integrations.Sdk.Validator, as: IntegrationSDK
  alias Contexla.Integrations.Sdk.Adapter
  alias Contexla.Integrations.Sdk.Definition

  defmodule ValidIntegration do
    @behaviour Contexla.Integrations.Sdk.Integration

    @impl true
    def definition do
      %Definition{
        id: "com.contexla.test.integration",
        name: "Test Integration",
        version: "1.0.0",
        otp_application: :test_integration,
        entry_module: __MODULE__,
        adapters: [
          %Adapter{
            id: "test.adapter.v1",
            contract: "test.contract.v1",
            module: __MODULE__,
            source_types: ["test.source.v1"]
          }
        ]
      }
    end

    def validate_source(_path, _opts), do: {:ok, %{}}
  end

  test "validates an Integration module and its Adapter catalog" do
    assert {:ok, definition} = IntegrationSDK.validate_module(ValidIntegration)
    assert definition.id == "com.contexla.test.integration"
    assert [%Adapter{contract: "test.contract.v1"}] = definition.adapters
  end

  test "rejects a module without a definition callback" do
    assert {:error, {:missing_callback, {:definition, 0}}} =
             IntegrationSDK.validate_module(__MODULE__)
  end
end
