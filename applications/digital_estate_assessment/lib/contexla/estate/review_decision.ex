defmodule Contexla.Estate.ReviewDecision do
  @moduledoc "Append-only record of a reviewer changing a Finding's disposition."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_review_decisions" do
    field(:finding_id, :binary_id)
    field(:reviewed_by_user_id, :binary_id)
    field(:from_status, Ecto.Enum, values: [:open, :accepted, :suppressed, :resolved])
    field(:to_status, Ecto.Enum, values: [:open, :accepted, :suppressed, :resolved])
    field(:rationale, :string)
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(decision, attrs) do
    decision
    |> cast(attrs, [:finding_id, :reviewed_by_user_id, :from_status, :to_status, :rationale])
    |> validate_required([
      :finding_id,
      :reviewed_by_user_id,
      :from_status,
      :to_status,
      :rationale
    ])
    |> validate_length(:rationale, min: 3, max: 4_000)
  end
end
