defmodule Contexla.Applications.Sdk.Requirement do
  @moduledoc "An exact Tool version required by an Application Operation."

  @enforce_keys [:tool_id, :version]
  defstruct [:tool_id, :version, optional: false]

  @type t :: %__MODULE__{}

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = requirement) do
    if non_empty?(requirement.tool_id) and non_empty?(requirement.version) and
         is_boolean(requirement.optional) do
      :ok
    else
      {:error, :invalid_tool_requirement}
    end
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
