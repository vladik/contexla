defmodule Contexla.Integrations.Drupal.AssessmentSnapshotAdapter do
  @moduledoc """
  Validates the offline Drupal snapshot profile before Contexla stores it.
  """

  @behaviour Contexla.Integrations.Sdk.SourceAdapter

  alias Contexla.Integrations.Drupal.Snapshot.Validator

  @impl true
  def validate_source(path, opts), do: Validator.validate(path, opts)

  @doc "Validates and normalizes an approved Drupal snapshot for Assessment."
  def normalize_source(path, opts \\ []) do
    with {:ok, validated} <- Validator.validate_and_read(path, opts) do
      Contexla.Integrations.Drupal.AssessmentSnapshotNormalizer.normalize(validated)
    end
  end
end
