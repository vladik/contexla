defmodule Contexla.Applications.ContentIntegrityMonitor.Observation do
  @moduledoc "One fact value observed at one Source for one entity during a Run."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_observations" do
    field(:ref_id, :string)
    field(:raw_value, :string)
    field(:normalized_value, :string)

    field(:state, Ecto.Enum,
      values: [:healthy, :pending, :overdue, :mismatch, :missing, :unavailable, :unknown]
    )

    field(:source_updated_at, :utc_datetime)
    field(:observed_at, :utc_datetime)
    belongs_to(:run, Contexla.Applications.ContentIntegrityMonitor.Run)
    belongs_to(:source, Contexla.Applications.ContentIntegrityMonitor.Source)
    belongs_to(:fact, Contexla.Applications.ContentIntegrityMonitor.Fact, foreign_key: :fact_id)
    belongs_to(:evidence, Contexla.Applications.ContentIntegrityMonitor.Evidence)
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(observation, attrs) do
    observation
    |> cast(attrs, [
      :run_id,
      :source_id,
      :fact_id,
      :evidence_id,
      :ref_id,
      :raw_value,
      :normalized_value,
      :state,
      :source_updated_at,
      :observed_at
    ])
    |> validate_required([
      :run_id,
      :source_id,
      :fact_id,
      :state,
      :observed_at
    ])
    |> unique_constraint([:run_id, :source_id, :fact_id, :ref_id])
  end
end
