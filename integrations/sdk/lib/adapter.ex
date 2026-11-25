defmodule Contexla.Integrations.Sdk.Adapter do
  @moduledoc """
  Declarative Adapter exposed by an Integration package.
  """

  @enforce_keys [:id, :contract, :module]
  defstruct [:id, :contract, :module, description: "", source_types: []]

  @type t :: %__MODULE__{
          id: String.t(),
          contract: String.t(),
          module: module(),
          description: String.t(),
          source_types: [String.t()]
        }
end
