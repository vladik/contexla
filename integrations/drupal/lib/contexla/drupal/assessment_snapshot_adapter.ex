defmodule Contexla.Drupal.AssessmentSnapshotAdapter do
  @moduledoc """
  Validates the offline Drupal snapshot profile before Contexla stores it.
  """

  @behaviour Contexla.IntegrationSDK.SourceAdapter

  alias Contexla.Drupal.Snapshot.Validator

  @impl true
  def validate_source(path, opts), do: Validator.validate(path, opts)

  @doc "Validates and normalizes an approved Drupal snapshot for Assessment."
  def normalize_source(path, opts \\ []) do
    with {:ok, validated} <- Validator.validate_and_read(path, opts) do
      Contexla.Drupal.AssessmentSnapshotNormalizer.normalize(validated)
    end
  end
end
