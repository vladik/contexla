defmodule Contexla.IntegrationSDK.Definition do
  @moduledoc """
  Declarative identity and Adapter catalog for a trusted Integration package.
  """

  alias Contexla.IntegrationSDK.Adapter

  @enforce_keys [:id, :name, :version, :otp_application, :entry_module]
  defstruct [
    :id,
    :name,
    :version,
    :otp_application,
    :entry_module,
    description: "",
    adapters: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          version: String.t(),
          otp_application: atom(),
          entry_module: module(),
          description: String.t(),
          adapters: [Adapter.t()]
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = definition) do
    valid? =
      non_empty_string?(definition.id) and
        non_empty_string?(definition.name) and
        non_empty_string?(definition.version) and
        is_atom(definition.otp_application) and
        is_atom(definition.entry_module) and
        is_binary(definition.description) and
        is_list(definition.adapters) and
        Enum.all?(definition.adapters, &valid_adapter?/1)

    if valid?, do: :ok, else: {:error, :invalid_definition_fields}
  end

  defp valid_adapter?(%Adapter{} = adapter) do
    non_empty_string?(adapter.id) and
      non_empty_string?(adapter.contract) and
      is_atom(adapter.module) and
      match?({:module, _module}, Code.ensure_loaded(adapter.module)) and
      function_exported?(adapter.module, :validate_source, 2) and
      is_binary(adapter.description) and
      is_list(adapter.source_types) and
      Enum.all?(adapter.source_types, &non_empty_string?/1)
  end

  defp valid_adapter?(_value), do: false
  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""
end
