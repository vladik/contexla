defmodule Contexla.Platform.Test.ToolRuntime.RegistryTest do
  use ExUnit.Case, async: true

  alias Contexla.Platform.ToolRuntime.Registry

  test "loads the bundled Tools" do
    tools = Registry.tools()
    assert length(tools) == 3
    tool = Enum.find(tools, &(&1.id == "com.contexla.dependencies.parse-composer"))
    assert tool.version == "2.0.0"
    assert tool.runtime == :native
    assert {:ok, ^tool} = Registry.fetch_tool(tool.id, tool.version)
  end
end
