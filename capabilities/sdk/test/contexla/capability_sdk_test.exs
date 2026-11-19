defmodule Contexla.CapabilitySDKTest do
  use ExUnit.Case

  alias Contexla.CapabilitySDK
  alias Contexla.CapabilitySDK.{Capability, Processor, Requirement}

  defmodule CapabilityPackage do
    def capabilities do
      [
        %Capability{
          id: "test.capability",
          contract_version: "1",
          name: "Test",
          purpose: "Exercise the SDK",
          input_schema: %{},
          output_schema: %{}
        }
      ]
    end
  end

  defmodule ProcessorPackage do
    def processors do
      [
        %Processor{
          id: "test.processor",
          version: "1.0.0",
          capability_id: "test.capability",
          capability_contract_version: "1",
          runtime: :native,
          entrypoint: __MODULE__
        }
      ]
    end
  end

  test "validates Capability and Processor packages independently" do
    assert {:ok, [%Capability{id: "test.capability"}]} =
             CapabilitySDK.validate_capability_package(CapabilityPackage)

    assert {:ok, [%Processor{id: "test.processor"}]} =
             CapabilitySDK.validate_processor_package(ProcessorPackage)
  end

  test "validates Application Capability requirements" do
    assert :ok =
             Requirement.validate(%Requirement{
               capability_id: "test.capability",
               contract_version: "1"
             })
  end
end
