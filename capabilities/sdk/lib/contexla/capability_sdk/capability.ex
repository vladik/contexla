defmodule Contexla.CapabilitySDK.Capability do
  @moduledoc """
  A reusable executable contract describing what Contexla can do.
  """

  @enforce_keys [:id, :contract_version, :name, :purpose, :input_schema, :output_schema]
  defstruct [
    :id,
    :contract_version,
    :name,
    :purpose,
    :input_schema,
    :output_schema,
    error_schema: %{},
    permissions: [],
    determinism: :deterministic,
    side_effects: :none,
    idempotency: :not_applicable,
    owner_scope: :platform,
    owner_key: "platform"
  ]

  @type t :: %__MODULE__{}

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = capability) do
    valid? =
      non_empty?(capability.id) and
        non_empty?(capability.contract_version) and
        non_empty?(capability.name) and
        non_empty?(capability.purpose) and
        is_map(capability.input_schema) and
        is_map(capability.output_schema) and
        is_map(capability.error_schema) and
        string_list?(capability.permissions) and
        capability.determinism in [:deterministic, :nondeterministic] and
        capability.side_effects in [:none, :read, :write, :external] and
        capability.idempotency in [:not_applicable, :idempotent, :non_idempotent] and
        capability.owner_scope in [:platform, :application, :instance] and
        non_empty?(capability.owner_key)

    if valid?, do: :ok, else: {:error, {:invalid_capability, capability.id}}
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
  defp string_list?(value), do: is_list(value) and Enum.all?(value, &non_empty?/1)
end
