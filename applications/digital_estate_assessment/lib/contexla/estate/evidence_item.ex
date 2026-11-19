defmodule Contexla.Estate.EvidenceItem do
  @moduledoc "A package-relative, immutable evidence item consumed by an Assessment Run."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_evidence_items" do
    field(:assessment_run_id, :binary_id)
    field(:artifact_id, :binary_id)
    field(:path, :string)
    field(:kind, :string)
    field(:media_type, :string)
    field(:sha256, :string)
    field(:byte_size, :integer)
    field(:metadata, :map, default: %{})
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :assessment_run_id,
      :artifact_id,
      :path,
      :kind,
      :media_type,
      :sha256,
      :byte_size,
      :metadata
    ])
    |> validate_required([
      :assessment_run_id,
      :artifact_id,
      :path,
      :kind,
      :media_type,
      :sha256,
      :byte_size,
      :metadata
    ])
    |> validate_format(:sha256, ~r/^[0-9a-f]{64}$/)
    |> unique_constraint([:assessment_run_id, :path])
  end
end
