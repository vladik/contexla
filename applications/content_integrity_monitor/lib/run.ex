defmodule Contexla.Applications.ContentIntegrityMonitor.Run do
  @moduledoc "One durable execution of a content-integrity Monitor."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_runs" do
    field(:application_instance_id, :binary_id)
    field(:initiated_by_user_id, :binary_id)
    field(:status, Ecto.Enum, values: [:queued, :running, :succeeded, :failed])

    field(:summary, :map, default: %{})
    field(:error, :map)
    field(:started_at, :utc_datetime)
    field(:completed_at, :utc_datetime)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    has_many(:source_checks, Contexla.Applications.ContentIntegrityMonitor.SourceCheck)
    timestamps(type: :utc_datetime)
  end

  def create_changeset(run, attrs) do
    run
    |> cast(attrs, [:monitor_id, :application_instance_id, :initiated_by_user_id, :status])
    |> validate_required([:monitor_id, :application_instance_id, :initiated_by_user_id, :status])
  end

  def status_changeset(run, attrs) do
    run
    |> cast(attrs, [:status, :summary, :error, :started_at, :completed_at])
    |> validate_required([:status])
  end
end
