defmodule Contexla.Applications.ContentIntegrityMonitor.Evidence do
  @moduledoc "Bounded source and extraction evidence retained by the Application."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_evidence" do
    field(:entity_id, :string)
    field(:tool_invocation_id, :binary_id)
    field(:response_sha256, :string)
    field(:media_type, :string)
    field(:excerpt, :string)
    field(:values, :map, default: %{})
    field(:observed_at, :utc_datetime)
    belongs_to(:run, Contexla.Applications.ContentIntegrityMonitor.Run)
    belongs_to(:source, Contexla.Applications.ContentIntegrityMonitor.Source)
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(evidence, attrs) do
    evidence
    |> cast(attrs, [
      :run_id,
      :source_id,
      :entity_id,
      :tool_invocation_id,
      :response_sha256,
      :media_type,
      :excerpt,
      :values,
      :observed_at
    ])
    |> validate_required([
      :run_id,
      :source_id,
      :response_sha256,
      :media_type,
      :excerpt,
      :values,
      :observed_at
    ])
    |> validate_format(:response_sha256, ~r/^[0-9a-f]{64}$/)
    |> unique_constraint([:run_id, :source_id, :entity_id])
  end
end
