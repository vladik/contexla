defmodule Contexla.CapabilitySDK.NativeProcessor do
  @moduledoc "Execution contract implemented by a native Elixir Processor."

  @callback execute(map(), map()) :: {:ok, map()} | {:error, term()}
end
