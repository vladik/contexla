defmodule Contexla.Capabilities.Bundled do
  @behaviour Contexla.CapabilitySDK.CapabilityPackage

  alias Contexla.CapabilitySDK.Capability

  @impl true
  def capabilities do
    [parse_composer()]
  end

  defp parse_composer do
    %Capability{
      id: "contexla.parse-composer",
      contract_version: "1.0.0",
      name: "Parse Composer",
      purpose: "Parse structured content from raw input (HTML, PDF, plain text) into named field values",
      input_schema: %{
        "type" => "object",
        "required" => ["content", "content_type", "field_mappings"],
        "properties" => %{
          "content" => %{"type" => "string"},
          "content_type" => %{
            "type" => "string",
            "enum" => ["text/html", "application/pdf", "text/plain", "text/csv"]
          },
          "field_mappings" => %{
            "type" => "array",
            "items" => %{
              "type" => "object",
              "required" => ["field_id", "selector"],
              "properties" => %{
                "field_id" => %{"type" => "string"},
                "selector" => %{"type" => "string"}
              }
            }
          }
        }
      },
      output_schema: %{
        "type" => "object",
        "required" => ["fields"],
        "properties" => %{
          "fields" => %{
            "type" => "object",
            "additionalProperties" => %{"type" => "string"}
          }
        }
      },
      error_schema: %{
        "type" => "object",
        "properties" => %{
          "code" => %{"type" => "string"},
          "message" => %{"type" => "string"}
        }
      },
      permissions: [],
      determinism: :deterministic,
      side_effects: :none,
      idempotency: :idempotent,
      owner_scope: :platform,
      owner_key: "platform"
    }
  end
end
