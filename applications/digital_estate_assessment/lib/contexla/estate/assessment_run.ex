defmodule Contexla.Estate.AssessmentRun do
  @moduledoc "One durable execution of the Digital Estate Assessment Application."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  @schema_prefix "contexla_estate"
  schema "estate_assessment_runs" do
    field(:application_instance_id, :binary_id)
    field(:source_artifact_id, :binary_id)
    field(:initiated_by_user_id, :binary_id)
    field(:status, Ecto.Enum, values: [:queued, :running, :succeeded, :failed])
    field(:adapter_id, :string)
    field(:adapter_version, :string)
    field(:rule_set_version, :string)
    field(:summary, :map, default: %{})
    field(:error, :map)
    field(:started_at, :utc_datetime)
    field(:completed_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  def create_changeset(run, attrs) do
    run
    |> cast(attrs, [
      :application_instance_id,
      :source_artifact_id,
      :initiated_by_user_id,
      :status,
      :adapter_id,
      :adapter_version,
      :rule_set_version
    ])
    |> validate_required([
      :application_instance_id,
      :source_artifact_id,
      :initiated_by_user_id,
      :status,
      :adapter_id,
      :adapter_version,
      :rule_set_version
    ])
  end

  def status_changeset(run, attrs) do
    run
    |> cast(attrs, [:status, :summary, :error, :started_at, :completed_at])
    |> validate_required([:status])
  end
end
