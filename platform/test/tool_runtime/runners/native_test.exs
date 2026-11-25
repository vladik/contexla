defmodule Contexla.Platform.Test.ToolRuntime.Runners.NativeTest do
  use ExUnit.Case, async: true

  alias Contexla.Platform.ToolRuntime.Runners.Native

  defmodule SuccessfulTool do
    def execute(input, _context), do: {:ok, input}
  end

  defmodule CrashingTool do
    def execute(_input, _context), do: raise("tool failed")
  end

  defmodule SlowTool do
    def execute(_input, _context) do
      Process.sleep(100)
      {:ok, %{}}
    end
  end

  test "returns a successful structured result" do
    assert {:ok, %{"value" => 1}} = Native.run(SuccessfulTool, %{"value" => 1}, %{}, 100)
  end

  test "normalizes a crashing Tool without crashing the caller" do
    assert {:execution_error, {:tool_crashed, {%RuntimeError{}, _stacktrace}}} =
             Native.run(CrashingTool, %{}, %{}, 100)
  end

  test "terminates a Tool that exceeds its timeout" do
    assert {:execution_error, :timeout} = Native.run(SlowTool, %{}, %{}, 1)
  end
end
