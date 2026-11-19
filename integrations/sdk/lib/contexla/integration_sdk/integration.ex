defmodule Contexla.IntegrationSDK.Integration do
  @moduledoc """
  Behaviour implemented by a trusted Integration package.
  """

  alias Contexla.IntegrationSDK.Definition

  @callback definition() :: Definition.t()
end
