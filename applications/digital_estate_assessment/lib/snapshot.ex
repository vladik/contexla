defmodule Contexla.Applications.DigitalEstateAssessment.Snapshot do
  @moduledoc "An immutable normalized view of one assessed Drupal target."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_snapshots" do
    field(:assessment_run_id, :binary_id)
    field(:target_key, :string)
    field(:adapter_id, :string)
    field(:adapter_version, :string)
    field(:collected_at, :utc_datetime)
    field(:limitations, {:array, :string}, default: [])
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [
      :assessment_run_id,
      :target_key,
      :adapter_id,
      :adapter_version,
      :collected_at,
      :limitations
    ])
    |> validate_required([
      :assessment_run_id,
      :target_key,
      :adapter_id,
      :adapter_version,
      :collected_at,
      :limitations
    ])
    |> unique_constraint([:assessment_run_id, :target_key])
  end
end
