defmodule Contexla.Applications.Sdk.Operation do
  @moduledoc """
  An operation exposed by an Application to the platform, UI, API, and agents.
  """

  alias Contexla.Tools.Sdk.Requirement

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    description: "",
    kind: :command,
    queue: :default,
    max_attempts: 3,
    timeout_seconds: 60,
    requires_approval: false,
    input_schema: %{"type" => "object", "properties" => %{}},
    required_tools: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          kind: :command | :read,
          queue: atom(),
          max_attempts: pos_integer(),
          timeout_seconds: pos_integer(),
          requires_approval: boolean(),
          input_schema: map(),
          required_tools: [Requirement.t()]
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = operation) do
    valid? =
      non_empty?(operation.id) and
        non_empty?(operation.name) and
        is_binary(operation.description) and
        operation.kind in [:command, :read] and
        is_atom(operation.queue) and
        is_integer(operation.max_attempts) and operation.max_attempts > 0 and
        is_integer(operation.timeout_seconds) and operation.timeout_seconds > 0 and
        is_boolean(operation.requires_approval) and
        is_map(operation.input_schema) and
        is_list(operation.required_tools) and
        Enum.all?(operation.required_tools, &(Requirement.validate(&1) == :ok))

    if valid?, do: :ok, else: {:error, {:invalid_operation, operation.id}}
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
