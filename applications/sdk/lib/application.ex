defmodule Contexla.Applications.Sdk.Application do
  @moduledoc """
  Behaviour implemented by a trusted Contexla Application package.

  `definition/0`, `available_operations/0`, and `required_adapter_contracts/0`
  are automatically implemented when you add `use Contexla.Applications.Sdk.Manifest`
  to your Package module. Only implement them manually if you are not using the
  manifest macro.
  """

  alias Contexla.Applications.Sdk.{Definition, Instance, Operation}

  @callback definition() :: Definition.t()
  @callback validate_instance_config(map()) :: {:ok, map()} | {:error, term()}
  @callback available_operations() :: [Operation.t()]
  @callback required_adapter_contracts() :: [String.t()]
  @callback migrate_install(module()) :: :ok | {:error, term()}

  @callback execute_operation(String.t(), Instance.t(), map()) ::
              {:ok, term()}
              | {:ok, term(), keyword()}
              | {:error, term()}
              | {:download, binary(), keyword()}

  @optional_callbacks migrate_install: 1, execute_operation: 3
end
