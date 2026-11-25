defmodule Contexla.Integrations.Sdk.Integration do
  @moduledoc """
  Behaviour implemented by a trusted Integration package.
  """

  alias Contexla.Integrations.Sdk.Definition

  @callback definition() :: Definition.t()
end
