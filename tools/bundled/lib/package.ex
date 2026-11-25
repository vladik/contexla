defmodule Contexla.Tools.Bundled.Package do
  @moduledoc "Trusted first-party Tools bundled with Contexla."

  @behaviour Contexla.Tools.Sdk.Package

  alias Contexla.Tools.Sdk.Tool

  @impl true
  def tools do
    [
      json_values(),
      html_values(),
      %Tool{
        id: "com.contexla.dependencies.parse-composer",
        version: "2.0.0",
        name: "Parse Composer Dependencies",
        purpose: "Return normalized dependency facts from Composer manifests.",
        runtime: :native,
        entrypoint: Contexla.Tools.Bundled.ParseComposerDependencies,
        input_schema: %{
          "type" => "object",
          "required" => ["composer_json", "composer_lock"],
          "properties" => %{
            "composer_json" => %{"type" => "object", "sensitive" => true},
            "composer_lock" => %{"type" => "object", "sensitive" => true}
          }
        },
        output_schema: %{
          "type" => "object",
          "required" => ["dependencies"],
          "properties" => %{
            "dependencies" => %{
              "type" => "array",
              "items" => %{
                "type" => "object",
                "required" => ["name", "version", "type", "development", "direct"],
                "additionalProperties" => false,
                "properties" => %{
                  "name" => %{"type" => "string"},
                  "version" => %{"type" => "string"},
                  "type" => %{"type" => "string"},
                  "development" => %{"type" => "boolean"},
                  "direct" => %{"type" => "boolean"}
                }
              }
            }
          }
        },
        determinism: :deterministic,
        side_effects: :none,
        idempotency: :not_applicable,
        timeout_ms: 5_000
      }
    ]
  end

  defp json_values do
    %Tool{
      id: "com.contexla.extract.json-values",
      version: "1.0.0",
      name: "Extract JSON Values",
      purpose: "Extract named values from a JSON object using bounded dotted paths.",
      runtime: :native,
      entrypoint: Contexla.Tools.Bundled.ExtractJsonValues,
      input_schema: extraction_input_schema("document", "object"),
      output_schema: extraction_output_schema(),
      determinism: :deterministic,
      side_effects: :none,
      idempotency: :not_applicable,
      timeout_ms: 5_000
    }
  end

  defp html_values do
    %Tool{
      id: "com.contexla.extract.html-values",
      version: "1.0.0",
      name: "Extract HTML Values",
      purpose: "Extract named text values from HTML using CSS selectors.",
      runtime: :native,
      entrypoint: Contexla.Tools.Bundled.ExtractHtmlValues,
      input_schema: extraction_input_schema("html", "string"),
      output_schema: extraction_output_schema(),
      determinism: :deterministic,
      side_effects: :none,
      idempotency: :not_applicable,
      timeout_ms: 5_000
    }
  end

  defp extraction_input_schema(document_key, document_type) do
    %{
      "type" => "object",
      "required" => [document_key, "mappings"],
      "additionalProperties" => false,
      "properties" => %{
        document_key => %{"type" => document_type, "sensitive" => true},
        "mappings" => %{"type" => "object"}
      }
    }
  end

  defp extraction_output_schema do
    %{
      "type" => "object",
      "required" => ["values"],
      "additionalProperties" => false,
      "properties" => %{"values" => %{"type" => "object"}}
    }
  end
end
