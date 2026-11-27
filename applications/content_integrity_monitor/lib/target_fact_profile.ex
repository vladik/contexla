defmodule Contexla.Applications.ContentIntegrityMonitor.TargetFactProfile do
  @moduledoc "Per-target configuration of whether a fact is expected and how to compare it."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_target_fact_profiles" do
    field(:expected, Ecto.Enum, values: [:required, :optional, :excluded], default: :required)
    field(:comparison_type, Ecto.Enum,
      values: [:exists, :text, :text_case_insensitive, :text_prefix, :numeric, :date, :regex]
    )
    field(:pattern, :string)
    belongs_to(:source, Contexla.Applications.ContentIntegrityMonitor.Source)
    belongs_to(:fact, Contexla.Applications.ContentIntegrityMonitor.Fact)
    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:source_id, :fact_id, :expected, :comparison_type, :pattern])
    |> validate_required([:source_id, :fact_id, :expected])
    |> unique_constraint([:source_id, :fact_id])
  end
end
