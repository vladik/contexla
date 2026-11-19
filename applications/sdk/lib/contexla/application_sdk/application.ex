defmodule Contexla.ApplicationSDK.Application do
  @moduledoc """
  Behaviour implemented by a trusted Contexla Application package.
  """

  alias Contexla.ApplicationSDK.{Definition, Instance}
  alias Contexla.ApplicationSDK.Operation

  @callback definition() :: Definition.t()

  @callback validate_instance_config(map()) ::
              {:ok, map()} | {:error, term()}

  @callback available_operations() :: [Operation.t()]

  @callback required_adapter_contracts() :: [String.t()]

  @callback migrate_install(module()) :: :ok | {:error, term()}

  @callback execute_operation(String.t(), Instance.t(), map()) ::
              {:ok, term()} | {:error, term()} | {:download, binary(), keyword()}

  @optional_callbacks migrate_install: 1, execute_operation: 3
end
