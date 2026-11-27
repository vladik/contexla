defmodule Contexla.CapabilitySDK.Processor do
  @moduledoc """
  A concrete implementation of one Capability contract.
  """

  @enforce_keys [
    :id,
    :version,
    :capability_id,
    :capability_contract_version,
    :runtime,
    :entrypoint
  ]
  defstruct [
    :id,
    :version,
    :capability_id,
    :capability_contract_version,
    :runtime,
    :entrypoint,
    dependency_spec: %{},
    config_schema: %{},
    requested_permissions: [],
    resource_limits: %{},
    timeout_ms: 30_000,
    owner_scope: :platform,
    owner_key: "platform",
    default: false
  ]

  @type t :: %__MODULE__{}

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = processor) do
    valid? =
      non_empty?(processor.id) and
        non_empty?(processor.version) and
        non_empty?(processor.capability_id) and
        non_empty?(processor.capability_contract_version) and
        processor.runtime in [:native, :python, :cli, :http] and
        valid_entrypoint?(processor.runtime, processor.entrypoint) and
        is_map(processor.dependency_spec) and
        is_map(processor.config_schema) and
        string_list?(processor.requested_permissions) and
        is_map(processor.resource_limits) and
        is_integer(processor.timeout_ms) and processor.timeout_ms > 0 and
        processor.owner_scope in [:platform, :application, :instance] and
        non_empty?(processor.owner_key) and
        is_boolean(processor.default)

    if valid?, do: :ok, else: {:error, {:invalid_processor, processor.id}}
  end

  defp valid_entrypoint?(:native, value), do: is_atom(value)
  defp valid_entrypoint?(_runtime, value), do: non_empty?(value)
  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
  defp string_list?(value), do: is_list(value) and Enum.all?(value, &non_empty?/1)
end
