defmodule Contexla.Tools.Bundled.Test.PackageTest do
  use ExUnit.Case, async: true

  test "declares valid bundled Tools with unique identities" do
    assert {:ok, tools} =
             Contexla.Tools.Sdk.Catalog.validate_package(Contexla.Tools.Bundled.Package)

    assert length(tools) == 3
    assert Enum.uniq_by(tools, &{&1.id, &1.version}) == tools
    assert Enum.all?(tools, &(&1.runtime == :native))
  end
end
