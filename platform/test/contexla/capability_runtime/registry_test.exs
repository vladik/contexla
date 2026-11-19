defmodule Contexla.CapabilityRuntime.RegistryTest do
  use ExUnit.Case, async: true

  alias Contexla.CapabilityRuntime.Registry

  test "loads the bundled Capability contract and native Processor" do
    assert [capability] = Registry.capabilities()
    assert capability.id == "com.contexla.dependencies.parse-composer"

    assert [processor] = Registry.processors()
    assert processor.capability_id == capability.id

    assert {:ok, ^capability} =
             Registry.fetch_capability(capability.id, capability.contract_version)

    assert {:ok, ^processor} = Registry.fetch_processor(processor.id, processor.version)
  end
end
