defmodule Contexla.CapabilitySDK.Requirement do
  @moduledoc """
  A Capability contract required by an Application Operation.
  """

  @enforce_keys [:capability_id, :contract_version]
  defstruct [:capability_id, :contract_version, optional: false]

  @type t :: %__MODULE__{}

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = requirement) do
    if non_empty?(requirement.capability_id) and
         non_empty?(requirement.contract_version) and
         is_boolean(requirement.optional) do
      :ok
    else
      {:error, :invalid_capability_requirement}
    end
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
