defmodule Contexla.CapabilitySDKTest do
  use ExUnit.Case, async: true

  alias Contexla.CapabilitySDK
  alias Contexla.CapabilitySDK.{Capability, Processor}

  defmodule ValidCapabilityPackage do
    @behaviour Contexla.CapabilitySDK.CapabilityPackage

    @impl true
    def capabilities do
      [
        %Capability{
          id: "cap-1",
          contract_version: "1.0.0",
          name: "Cap One",
          purpose: "Test capability",
          input_schema: %{},
          output_schema: %{}
        }
      ]
    end
  end

  defmodule DuplicateCapabilityPackage do
    @behaviour Contexla.CapabilitySDK.CapabilityPackage

    @impl true
    def capabilities do
      [
        %Capability{
          id: "cap-1",
          contract_version: "1.0.0",
          name: "Cap One",
          purpose: "Test capability",
          input_schema: %{},
          output_schema: %{}
        },
        %Capability{
          id: "cap-1",
          contract_version: "1.0.0",
          name: "Cap One Again",
          purpose: "Duplicate",
          input_schema: %{},
          output_schema: %{}
        }
      ]
    end
  end

  defmodule ValidProcessorPackage do
    @behaviour Contexla.CapabilitySDK.ProcessorPackage

    @impl true
    def processors do
      [
        %Processor{
          id: "proc-1",
          version: "1.0.0",
          capability_id: "cap-1",
          capability_contract_version: "1.0.0",
          runtime: :native,
          entrypoint: MyNativeProcessor
        }
      ]
    end
  end

  defmodule DuplicateProcessorPackage do
    @behaviour Contexla.CapabilitySDK.ProcessorPackage

    @impl true
    def processors do
      [
        %Processor{
          id: "proc-1",
          version: "1.0.0",
          capability_id: "cap-1",
          capability_contract_version: "1.0.0",
          runtime: :native,
          entrypoint: MyNativeProcessor
        },
        %Processor{
          id: "proc-1",
          version: "1.0.0",
          capability_id: "cap-1",
          capability_contract_version: "1.0.0",
          runtime: :native,
          entrypoint: MyNativeProcessorDuplicate
        }
      ]
    end
  end

  describe "validate_capability_package/1" do
    test "returns :ok for a valid package" do
      assert {:ok, _} = CapabilitySDK.validate_capability_package(ValidCapabilityPackage)
    end

    test "returns error for duplicate capability ids" do
      assert {:error, _} = CapabilitySDK.validate_capability_package(DuplicateCapabilityPackage)
    end
  end

  describe "validate_processor_package/1" do
    test "returns :ok for a valid package" do
      assert {:ok, _} = CapabilitySDK.validate_processor_package(ValidProcessorPackage)
    end

    test "returns error for duplicate processor ids" do
      assert {:error, _} = CapabilitySDK.validate_processor_package(DuplicateProcessorPackage)
    end
  end

  describe "Capability.validate/1" do
    test "valid capability passes" do
      cap = %Capability{
        id: "my-cap",
        contract_version: "1.0.0",
        name: "My Capability",
        purpose: "Does something useful",
        input_schema: %{},
        output_schema: %{}
      }

      assert :ok = Capability.validate(cap)
    end

    test "empty id fails" do
      cap = %Capability{
        id: "",
        contract_version: "1.0.0",
        name: "My Capability",
        purpose: "Does something useful",
        input_schema: %{},
        output_schema: %{}
      }

      assert {:error, _} = Capability.validate(cap)
    end
  end

  describe "Processor.validate/1" do
    test "valid native processor passes" do
      proc = %Processor{
        id: "my-proc",
        version: "1.0.0",
        capability_id: "my-cap",
        capability_contract_version: "1.0.0",
        runtime: :native,
        entrypoint: MyModule
      }

      assert :ok = Processor.validate(proc)
    end

    test "invalid runtime fails" do
      proc = %Processor{
        id: "my-proc",
        version: "1.0.0",
        capability_id: "my-cap",
        capability_contract_version: "1.0.0",
        runtime: :unknown,
        entrypoint: "some_entrypoint"
      }

      assert {:error, _} = Processor.validate(proc)
    end
  end
end
