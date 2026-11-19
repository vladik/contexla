defmodule Contexla.ApplicationSDK.Application do
  @moduledoc """
  Behaviour implemented by a trusted Contexla Application package.
  """

  alias Contexla.ApplicationSDK.Definition
  alias Contexla.ApplicationSDK.Operation

  @callback definition() :: Definition.t()

  @callback validate_instance_config(map()) ::
              {:ok, map()} | {:error, term()}

  @callback available_operations() :: [Operation.t()]

  @callback required_adapter_contracts() :: [String.t()]
end
