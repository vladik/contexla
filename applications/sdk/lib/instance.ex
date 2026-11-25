defmodule Contexla.Applications.Sdk.Instance do
  @moduledoc "Platform-neutral context supplied to an installed Application."

  @enforce_keys [:id, :application_id, :application_version, :name, :config, :actor_id]
  defstruct [
    :id,
    :application_id,
    :application_version,
    :name,
    :description,
    :status,
    :config,
    :actor_id
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          application_id: String.t(),
          application_version: String.t(),
          name: String.t(),
          description: String.t() | nil,
          status: atom() | String.t() | nil,
          config: map(),
          actor_id: String.t()
        }

  @doc "Builds a bounded Instance from the string-keyed session supplied by the platform."
  @spec from_session!(map()) :: t()
  def from_session!(
        %{
          "id" => id,
          "application_id" => application_id,
          "application_version" => application_version,
          "name" => name,
          "config" => config,
          "actor_id" => actor_id
        } = data
      ) do
    %__MODULE__{
      id: id,
      application_id: application_id,
      application_version: application_version,
      name: name,
      description: Map.get(data, "description"),
      status: Map.get(data, "status"),
      config: config,
      actor_id: actor_id
    }
  end

  def from_session!(data) do
    raise ArgumentError, "invalid Application Instance session: #{inspect(data)}"
  end
end
