defmodule Contexla.Capabilities.Bundled do
  @moduledoc """
  First-party Capability contracts bundled with Contexla.
  """

  @behaviour Contexla.CapabilitySDK.CapabilityPackage

  alias Contexla.CapabilitySDK.Capability

  @impl true
  def capabilities do
    [
      %Capability{
        id: "com.contexla.dependencies.parse-composer",
        contract_version: "1",
        name: "Parse Composer Dependencies",
        purpose: "Return normalized dependency facts from Composer manifests.",
        input_schema: %{
          "type" => "object",
          "required" => ["composer_json", "composer_lock"],
          "properties" => %{
            "composer_json" => %{"type" => "object"},
            "composer_lock" => %{"type" => "object"}
          }
        },
        output_schema: %{
          "type" => "object",
          "required" => ["dependencies"],
          "properties" => %{
            "dependencies" => %{
              "type" => "array",
              "items" => %{"type" => "object"}
            }
          }
        },
        determinism: :deterministic,
        side_effects: :none,
        idempotency: :not_applicable
      }
    ]
  end
end
