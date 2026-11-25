defmodule Contexla.Tools.Sdk.Tool do
  @moduledoc "A small, versioned executable unit that performs one bounded operation."

  @enforce_keys [
    :id,
    :version,
    :name,
    :purpose,
    :runtime,
    :entrypoint,
    :input_schema,
    :output_schema
  ]
  defstruct [
    :id,
    :version,
    :name,
    :purpose,
    :runtime,
    :entrypoint,
    :input_schema,
    :output_schema,
    error_schema: %{},
    dependency_spec: %{},
    permissions: [],
    resource_limits: %{},
    timeout_ms: 30_000,
    determinism: :deterministic,
    side_effects: :none,
    idempotency: :not_applicable,
    worker_profile: "light_tools",
    platform: "any",
    architectures: [],
    features: [],
    package_sha256: nil,
    package_artifact_id: nil,
    owner_scope: :platform,
    owner_key: "platform"
  ]

  @type t :: %__MODULE__{}

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = tool) do
    valid? =
      non_empty?(tool.id) and
        non_empty?(tool.version) and
        non_empty?(tool.name) and
        non_empty?(tool.purpose) and
        tool.runtime in [:native, :python, :cli, :node] and
        valid_entrypoint?(tool.runtime, tool.entrypoint) and
        is_map(tool.input_schema) and
        is_map(tool.output_schema) and
        is_map(tool.error_schema) and
        is_map(tool.dependency_spec) and
        string_list?(tool.permissions) and
        is_map(tool.resource_limits) and
        is_integer(tool.timeout_ms) and tool.timeout_ms > 0 and
        tool.determinism in [:deterministic, :nondeterministic] and
        tool.side_effects in [:none, :read, :write, :external] and
        tool.idempotency in [:not_applicable, :idempotent, :non_idempotent] and
        non_empty?(tool.worker_profile) and
        non_empty?(tool.platform) and
        string_list?(tool.architectures) and
        string_list?(tool.features) and
        optional_string?(tool.package_sha256) and
        tool.owner_scope in [:platform, :application, :instance] and
        non_empty?(tool.owner_key)

    if valid?, do: :ok, else: {:error, {:invalid_tool, tool.id}}
  end

  defp valid_entrypoint?(:native, value), do: is_atom(value)

  defp valid_entrypoint?(_runtime, value) when is_list(value),
    do: string_list?(value) and value != []

  defp valid_entrypoint?(_runtime, value), do: non_empty?(value)
  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
  defp optional_string?(nil), do: true
  defp optional_string?(value), do: non_empty?(value)
  defp string_list?(value), do: is_list(value) and Enum.all?(value, &non_empty?/1)
end
