defmodule Contexla.Applications.ContentIntegrityMonitor.Issue do
  @moduledoc "An operational integrity problem with an explicit lifecycle."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_issues" do
    field(:kind, Ecto.Enum, values: [:overdue, :mismatch, :missing, :unavailable])
    field(:status, Ecto.Enum, values: [:open, :acknowledged, :resolved], default: :open)
    field(:summary, :string)
    field(:occurrence_count, :integer, default: 1)
    field(:first_seen_at, :utc_datetime)
    field(:last_seen_at, :utc_datetime)
    field(:resolved_at, :utc_datetime)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    belongs_to(:source, Contexla.Applications.ContentIntegrityMonitor.Source)
    belongs_to(:fact_definition, Contexla.Applications.ContentIntegrityMonitor.FactDefinition)
    belongs_to(:current_observation, Contexla.Applications.ContentIntegrityMonitor.Observation)
    timestamps(type: :utc_datetime)
  end

  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [
      :monitor_id,
      :source_id,
      :fact_definition_id,
      :current_observation_id,
      :kind,
      :status,
      :summary,
      :occurrence_count,
      :first_seen_at,
      :last_seen_at,
      :resolved_at
    ])
    |> validate_required([
      :monitor_id,
      :source_id,
      :fact_definition_id,
      :kind,
      :status,
      :summary,
      :occurrence_count,
      :first_seen_at,
      :last_seen_at
    ])
    |> validate_number(:occurrence_count, greater_than: 0)
  end
end
