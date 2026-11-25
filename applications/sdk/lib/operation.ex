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
    input_schema: %{"type" => "object", "properties" => %{}},
    requires_approval: false,
    required_tools: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          kind: :command | :read,
          input_schema: map(),
          requires_approval: boolean(),
          required_tools: [Requirement.t()]
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = operation) do
    valid? =
      non_empty?(operation.id) and
        non_empty?(operation.name) and
        is_binary(operation.description) and
        operation.kind in [:command, :read] and
        is_map(operation.input_schema) and
        is_boolean(operation.requires_approval) and
        is_list(operation.required_tools) and
        Enum.all?(operation.required_tools, &(Requirement.validate(&1) == :ok))

    if valid?, do: :ok, else: {:error, {:invalid_operation, operation.id}}
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
