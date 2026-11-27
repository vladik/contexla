defmodule Contexla.Processors.Native do
  @behaviour Contexla.CapabilitySDK.ProcessorPackage

  alias Contexla.CapabilitySDK.Processor

  @impl true
  def processors do
    [parse_composer_processor()]
  end

  defp parse_composer_processor do
    %Processor{
      id: "contexla.processors.native.parse-composer",
      version: "1.0.0",
      capability_id: "contexla.parse-composer",
      capability_contract_version: "1.0.0",
      runtime: :native,
      entrypoint: Contexla.Processors.Native.ParseComposer,
      dependency_spec: %{},
      config_schema: %{},
      requested_permissions: [],
      resource_limits: %{},
      timeout_ms: 30_000,
      owner_scope: :platform,
      owner_key: "platform",
      default: true
    }
  end
end
