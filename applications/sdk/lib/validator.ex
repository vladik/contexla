defmodule Contexla.Applications.Sdk.Validator do
  @moduledoc """
  Contracts shared by Contexla and trusted Application packages.

  The SDK is intentionally independent of the platform database and web layer.
  Reading or validating a definition must not perform I/O.
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
         :ok <- Definition.validate(definition),
         :ok <- validate_declared_operations(module, definition),
         :ok <- validate_declared_adapters(module, definition) do
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

  defp validate_declared_operations(module, definition) do
    if module.available_operations() == definition.operations do
      :ok
    else
      {:error, :operation_definition_mismatch}
    end
  end

  defp validate_declared_adapters(module, definition) do
    if module.required_adapter_contracts() == definition.required_adapter_contracts do
      :ok
    else
      {:error, :adapter_contract_definition_mismatch}
    end
  end
end
