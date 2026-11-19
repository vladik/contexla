defmodule Contexla.CapabilitySDK do
  @moduledoc """
  Stable contracts shared by Capability definitions, Processor packages, and
  the Contexla runtime.
  """

  alias Contexla.CapabilitySDK.{Capability, Processor}

  @spec validate_capability_package(module()) ::
          {:ok, [Capability.t()]} | {:error, term()}
  def validate_capability_package(module) do
    with :ok <- callback_available(module, :capabilities, 0),
         capabilities when is_list(capabilities) <- module.capabilities(),
         :ok <- validate_all(capabilities, &Capability.validate/1),
         :ok <- unique(capabilities, &{&1.id, &1.contract_version}) do
      {:ok, capabilities}
    else
      {:error, _reason} = error -> error
      value -> {:error, {:invalid_capability_package, value}}
    end
  end

  @spec validate_processor_package(module()) :: {:ok, [Processor.t()]} | {:error, term()}
  def validate_processor_package(module) do
    with :ok <- callback_available(module, :processors, 0),
         processors when is_list(processors) <- module.processors(),
         :ok <- validate_all(processors, &Processor.validate/1),
         :ok <- unique(processors, &{&1.id, &1.version}) do
      {:ok, processors}
    else
      {:error, _reason} = error -> error
      value -> {:error, {:invalid_processor_package, value}}
    end
  end

  defp callback_available(module, name, arity) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, name, arity) do
      :ok
    else
      false -> {:error, {:missing_callback, {name, arity}}}
      {:error, reason} -> {:error, {:module_not_loaded, reason}}
    end
  end

  defp validate_all(items, validator) do
    Enum.reduce_while(items, :ok, fn item, :ok ->
      case validator.(item) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp unique(items, identity) do
    identities = Enum.map(items, identity)

    if length(identities) == length(Enum.uniq(identities)),
      do: :ok,
      else: {:error, :duplicate_identity}
  end
end
