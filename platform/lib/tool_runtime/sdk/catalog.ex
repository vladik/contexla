defmodule Contexla.Tools.Sdk.Catalog do
  @moduledoc "Stable contracts shared by Tool packages and the Contexla Tool Runtime."

  alias Contexla.Tools.Sdk.Tool

  @spec validate_package(module()) :: {:ok, [Tool.t()]} | {:error, term()}
  def validate_package(module) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :tools, 0),
         tools when is_list(tools) <- module.tools(),
         :ok <- validate_all(tools),
         :ok <- unique(tools) do
      {:ok, tools}
    else
      false -> {:error, {:missing_callback, {:tools, 0}}}
      {:error, _reason} = error -> error
      value -> {:error, {:invalid_tool_package, value}}
    end
  end

  defp validate_all(tools) do
    Enum.reduce_while(tools, :ok, fn tool, :ok ->
      case Tool.validate(tool) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp unique(tools) do
    identities = Enum.map(tools, &{&1.id, &1.version})

    if length(identities) == length(Enum.uniq(identities)),
      do: :ok,
      else: {:error, :duplicate_identity}
  end
end
