defmodule Contexla.ApplicationSDK.Instance do
  @moduledoc "Platform-neutral context supplied to an installed Application."

  @enforce_keys [:id, :application_id, :application_version, :name, :config, :actor_id]
  defstruct [:id, :application_id, :application_version, :name, :status, :config, :actor_id]

  @type t :: %__MODULE__{
          id: String.t(),
          application_id: String.t(),
          application_version: String.t(),
          name: String.t(),
          status: atom() | String.t() | nil,
          config: map(),
          actor_id: String.t()
        }
end
