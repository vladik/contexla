defmodule Contexla.Applications.ContentIntegrityMonitor.SourceCheck do
  @moduledoc "Durable acquisition and evidence state for one Source in a Run."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_source_checks" do
    field(:ref_id, :string)
    field(:status, Ecto.Enum, values: [:pending, :completed, :failed])
    field(:http_status, :integer)
    field(:fetched_at, :utc_datetime)
    field(:response_sha256, :string)
    field(:media_type, :string)
    field(:excerpt, :string)
    field(:error, :map)
    belongs_to(:run, Contexla.Applications.ContentIntegrityMonitor.Run)
    belongs_to(:source, Contexla.Applications.ContentIntegrityMonitor.Source)
    timestamps(type: :utc_datetime)
  end

  def changeset(check, attrs) do
    check
    |> cast(attrs, [
      :run_id,
      :source_id,
      :ref_id,
      :status,
      :http_status,
      :fetched_at,
      :response_sha256,
      :media_type,
      :excerpt,
      :error
    ])
    |> validate_required([:run_id, :source_id, :status])
    |> unique_constraint([:run_id, :source_id, :ref_id])
  end
end
