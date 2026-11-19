defmodule Contexla.IntegrationSDK do
  @moduledoc """
  Contracts shared by Contexla and trusted Integration packages.
  """

  alias Contexla.IntegrationSDK.Definition

  @spec validate_module(module()) :: {:ok, Definition.t()} | {:error, term()}
  def validate_module(module) when is_atom(module) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :definition, 0),
         %Definition{} = definition <- module.definition(),
         :ok <- Definition.validate(definition) do
      {:ok, definition}
    else
      {:error, _reason} = error -> error
      false -> {:error, {:missing_callback, {:definition, 0}}}
      value -> {:error, {:invalid_definition, value}}
    end
  end
end
