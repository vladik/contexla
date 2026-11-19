defmodule Contexla.Drupal.AssessmentSnapshotAdapter do
  @moduledoc """
  Validates the offline Drupal snapshot profile before Contexla stores it.
  """

  @behaviour Contexla.IntegrationSDK.SourceAdapter

  alias Contexla.Drupal.Snapshot.Validator

  @impl true
  def validate_source(path, opts), do: Validator.validate(path, opts)
end
