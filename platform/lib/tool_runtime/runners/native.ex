defmodule Contexla.Platform.ToolRuntime.Runners.Native do
  @moduledoc "Executes a trusted in-VM native Tool with a bounded timeout."

  def run(module, input, context, timeout_ms) when is_atom(module) do
    task =
      Task.Supervisor.async_nolink(
        Contexla.Platform.ToolRuntime.TaskSupervisor,
        fn -> module.execute(input, context) end
      )

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, output}} when is_map(output) -> {:ok, output}
      {:ok, {:error, reason}} -> {:tool_error, reason}
      {:ok, other} -> {:execution_error, {:invalid_tool_result, other}}
      {:exit, reason} -> {:execution_error, {:tool_crashed, reason}}
      nil -> {:execution_error, :timeout}
    end
  end
end
