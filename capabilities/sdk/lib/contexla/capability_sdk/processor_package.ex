defmodule Contexla.CapabilitySDK.ProcessorPackage do
  @moduledoc "A package that registers Processors."

  alias Contexla.CapabilitySDK.Processor

  @callback processors() :: [Processor.t()]
end
