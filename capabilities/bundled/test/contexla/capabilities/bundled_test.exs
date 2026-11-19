defmodule Contexla.Capabilities.BundledTest do
  use ExUnit.Case

  test "registers Parse Composer Dependencies as a stable Capability contract" do
    assert {:ok, [capability]} =
             Contexla.CapabilitySDK.validate_capability_package(Contexla.Capabilities.Bundled)

    assert capability.id == "com.contexla.dependencies.parse-composer"
    assert capability.contract_version == "1"
    assert capability.side_effects == :none
  end
end
