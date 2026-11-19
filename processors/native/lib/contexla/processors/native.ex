defmodule Contexla.Processors.Native do
  @moduledoc """
  Native Elixir Processors bundled with Contexla.
  """

  @behaviour Contexla.CapabilitySDK.ProcessorPackage

  alias Contexla.CapabilitySDK.Processor

  @impl true
  def processors do
    [
      %Processor{
        id: "com.contexla.processor.composer.native",
        version: "0.1.0",
        capability_id: "com.contexla.dependencies.parse-composer",
        capability_contract_version: "1",
        runtime: :native,
        entrypoint: Contexla.Processors.Native.ParseComposerDependencies,
        timeout_ms: 5_000,
        default: true
      }
    ]
  end
end
