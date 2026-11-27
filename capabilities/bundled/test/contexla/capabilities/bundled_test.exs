defmodule Contexla.Capabilities.BundledTest do
  use ExUnit.Case, async: true

  alias Contexla.Capabilities.Bundled
  alias Contexla.CapabilitySDK
  alias Contexla.CapabilitySDK.Capability

  describe "capabilities/0" do
    test "returns a non-empty list" do
      caps = Bundled.capabilities()
      assert is_list(caps)
      assert length(caps) > 0
    end

    test "all capabilities are valid" do
      for cap <- Bundled.capabilities() do
        assert :ok = Capability.validate(cap)
      end
    end

    test "package validates successfully" do
      assert {:ok, _} = CapabilitySDK.validate_capability_package(Bundled)
    end

    test "includes parse-composer capability" do
      ids = Bundled.capabilities() |> Enum.map(& &1.id)
      assert "contexla.parse-composer" in ids
    end
  end
end
