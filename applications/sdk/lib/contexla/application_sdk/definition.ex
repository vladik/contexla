defmodule Contexla.ApplicationSDK.Definition do
  @moduledoc """
  Declarative identity and contract for a trusted Application package.
  """

  alias Contexla.ApplicationSDK.Operation

  @enforce_keys [:id, :name, :version, :otp_application, :entry_module]
  defstruct [
    :id,
    :name,
    :version,
    :otp_application,
    :entry_module,
    description: "",
    config_schema: %{},
    operations: [],
    required_adapter_contracts: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          version: String.t(),
          otp_application: atom(),
          entry_module: module(),
          description: String.t(),
          config_schema: map(),
          operations: [Operation.t()],
          required_adapter_contracts: [String.t()]
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = definition) do
    validators = [
      {:id, definition.id, &non_empty_string?/1},
      {:name, definition.name, &non_empty_string?/1},
      {:version, definition.version, &non_empty_string?/1},
      {:otp_application, definition.otp_application, &is_atom/1},
      {:entry_module, definition.entry_module, &is_atom/1},
      {:description, definition.description, &is_binary/1},
      {:config_schema, definition.config_schema, &is_map/1},
      {:operations, definition.operations, &operations?/1},
      {:required_adapter_contracts, definition.required_adapter_contracts, &string_list?/1}
    ]

    case Enum.find(validators, fn {_field, value, validator} -> not validator.(value) end) do
      nil -> :ok
      {field, value, _validator} -> {:error, {:invalid_field, field, value}}
    end
  end

  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp operations?(value),
    do:
      is_list(value) and
        Enum.all?(value, &(match?(%Operation{}, &1) and Operation.validate(&1) == :ok))

  defp string_list?(value), do: is_list(value) and Enum.all?(value, &non_empty_string?/1)
end
