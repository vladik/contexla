defmodule Contexla.Integrations.Drupal.Package do
  @moduledoc """
  Drupal Integration package.
  """

  @behaviour Contexla.Integrations.Sdk.Integration

  alias Contexla.Integrations.Sdk.Adapter
  alias Contexla.Integrations.Sdk.Definition

  @impl true
  def definition do
    %Definition{
      id: "com.contexla.integration.drupal",
      name: "Drupal",
      version: "0.1.0",
      otp_application: :contexla_drupal,
      entry_module: __MODULE__,
      description: "Acquire and normalize approved evidence from Drupal estates.",
      adapters: [
        %Adapter{
          id: "drupal.assessment.snapshot.v1",
          contract: "contexla.estate.source.v1",
          module: Contexla.Integrations.Drupal.AssessmentSnapshotAdapter,
          description: "Normalize a validated Drupal snapshot for Digital Estate Assessment.",
          source_types: ["contexla.drupal-snapshot.v1"]
        }
      ]
    }
  end
end
