defmodule Contexla.CapabilitySDK.CapabilityPackage do
  @moduledoc "A package that registers Capability contracts."

  alias Contexla.CapabilitySDK.Capability

  @callback capabilities() :: [Capability.t()]
end
