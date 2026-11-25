defmodule Contexla.Tools.Sdk.NativeTool do
  @moduledoc "Execution contract implemented by a trusted native Elixir Tool."

  @callback execute(map(), map()) :: {:ok, map()} | {:error, term()}
end
