defmodule Contexla.CapabilityRuntime.Runners.Native do
  @moduledoc "Executes a trusted in-VM native Processor with a bounded timeout."

  def run(module, input, context, timeout_ms) when is_atom(module) do
    task = Task.async(fn -> module.execute(input, context) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, output}} when is_map(output) -> {:ok, output}
      {:ok, {:error, reason}} -> {:error, reason}
      {:ok, other} -> {:error, {:invalid_processor_result, other}}
      {:exit, reason} -> {:error, {:processor_crashed, reason}}
      nil -> {:error, :timeout}
    end
  end
end
