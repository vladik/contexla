defmodule Contexla.Applications.DigitalEstateAssessment.Rules do
  @moduledoc "Initial deterministic, evidence-only rules for Digital Estate Assessment."

  @version "1"
  @expected_files ~w(drupal-status.json modules.json themes.json sites.json content-types.json fields.json)

  def evaluate(normalized) do
    missing_evidence(normalized) ++
      unknown_version(normalized) ++ incomplete_custom_modules(normalized)
  end

  defp missing_evidence(normalized) do
    available = normalized.evidence |> Enum.map(&Path.basename(&1.path)) |> MapSet.new()

    @expected_files
    |> Enum.reject(&MapSet.member?(available, &1))
    |> Enum.map(fn file ->
      finding(
        "evidence.missing.#{file}",
        "evidence_gap",
        :medium,
        :high,
        "Expected evidence is missing: #{file}",
        "The snapshot does not contain #{file}; absence cannot be interpreted as an empty inventory.",
        "Collect the missing evidence or record why it is outside the agreed scope."
      )
    end)
  end

  defp unknown_version(normalized) do
    cms = Enum.find(normalized.resources, &(&1.kind == "cms"))
    version = cms && (cms.attributes["drupal_version"] || cms.attributes["version"])

    if is_binary(version) and String.trim(version) != "" do
      []
    else
      [
        finding(
          "drupal.version.unknown",
          "evidence_gap",
          :medium,
          :high,
          "Drupal version is unknown",
          "The supplied Drupal status evidence does not identify a Drupal version.",
          "Collect Drupal runtime status before making lifecycle or upgrade conclusions."
        )
      ]
    end
  end

  defp incomplete_custom_modules(normalized) do
    normalized.resources
    |> Enum.filter(&(&1.kind == "module" and custom?(&1.attributes)))
    |> Enum.flat_map(fn resource ->
      missing = Enum.reject(["owner", "repository"], &present?(resource.attributes[&1]))

      if missing == [] do
        []
      else
        [
          finding(
            "custom_module.maintenance_metadata_missing",
            "technical_debt",
            :medium,
            :high,
            "Custom module lacks maintenance metadata: #{resource.name}",
            "The custom module does not declare #{Enum.join(missing, " and ")}.",
            "Identify its owner and source repository before estimating modernization work."
          )
          |> Map.put(:resource_key, {resource.kind, resource.external_key})
          |> Map.put(:evidence_path, resource.evidence_path)
        ]
      end
    end)
  end

  defp custom?(attrs), do: attrs["origin"] == "custom" or attrs["type"] == "custom"
  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp finding(rule_id, category, severity, confidence, summary, explanation, recommendation) do
    %{
      rule_id: rule_id,
      rule_version: @version,
      category: category,
      severity: severity,
      confidence: confidence,
      summary: summary,
      explanation: explanation,
      recommendation: recommendation,
      status: :open
    }
  end
end
