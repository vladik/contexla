defmodule Contexla.Applications.Sdk.Validator do
  @moduledoc """
  Validates a compiled Application package module against its Definition.
  The Definition is derived from the manifest, so only the entry_module
  identity and runtime callbacks are checked here.
  """

  alias Contexla.Applications.Sdk.Definition

  @required_callbacks [
    definition: 0,
    validate_instance_config: 1,
    available_operations: 0,
    required_adapter_contracts: 0
  ]

  @spec validate_module(module()) :: {:ok, Definition.t()} | {:error, term()}
  def validate_module(module) when is_atom(module) do
    with :ok <- ensure_loaded(module),
         :ok <- ensure_callbacks(module),
         %Definition{} = definition <- module.definition(),
         :ok <- Definition.validate(definition) do
      {:ok, definition}
    else
      {:error, _reason} = error -> error
      value -> {:error, {:invalid_definition, value}}
    end
  end

  defp ensure_loaded(module) do
    case Code.ensure_loaded(module) do
      {:module, ^module} -> :ok
      {:error, reason} -> {:error, {:module_not_loaded, reason}}
    end
  end

  defp ensure_callbacks(module) do
    case Enum.reject(@required_callbacks, fn {name, arity} ->
           function_exported?(module, name, arity)
         end) do
      [] -> :ok
      missing -> {:error, {:missing_callbacks, missing}}
    end
  end
end
