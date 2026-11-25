defmodule Contexla.Applications.DigitalEstateAssessment.SnapshotComparison do
  @moduledoc "An immutable comparison between consecutive normalized estate snapshots."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_snapshot_comparisons" do
    field(:previous_snapshot_id, :binary_id)
    field(:current_snapshot_id, :binary_id)
    field(:summary, :map, default: %{})
    field(:changes, :map, default: %{})
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(comparison, attrs) do
    comparison
    |> cast(attrs, [:previous_snapshot_id, :current_snapshot_id, :summary, :changes])
    |> validate_required([:previous_snapshot_id, :current_snapshot_id, :summary, :changes])
    |> unique_constraint(:current_snapshot_id)
  end
end
