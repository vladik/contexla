defmodule Contexla.Estate.Finding do
  @moduledoc "An evidence-linked deterministic or expert Assessment conclusion."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_findings" do
    field(:assessment_run_id, :binary_id)
    field(:inventory_item_id, :binary_id)
    field(:evidence_item_id, :binary_id)
    field(:created_by_user_id, :binary_id)
    field(:origin, Ecto.Enum, values: [:deterministic, :expert], default: :deterministic)
    field(:rule_id, :string)
    field(:rule_version, :string)
    field(:category, :string)
    field(:severity, Ecto.Enum, values: [:info, :low, :medium, :high, :critical])
    field(:confidence, Ecto.Enum, values: [:low, :medium, :high])
    field(:summary, :string)
    field(:explanation, :string)
    field(:recommendation, :string)
    field(:status, Ecto.Enum, values: [:open, :accepted, :suppressed, :resolved], default: :open)
    timestamps(type: :utc_datetime)
  end

  def changeset(finding, attrs) do
    finding
    |> cast(attrs, [
      :assessment_run_id,
      :inventory_item_id,
      :evidence_item_id,
      :created_by_user_id,
      :origin,
      :rule_id,
      :rule_version,
      :category,
      :severity,
      :confidence,
      :summary,
      :explanation,
      :recommendation,
      :status
    ])
    |> validate_required([
      :assessment_run_id,
      :origin,
      :category,
      :severity,
      :confidence,
      :summary,
      :explanation,
      :recommendation,
      :status
    ])
    |> validate_origin()
  end

  def status_changeset(finding, status) do
    finding
    |> cast(%{status: status}, [:status])
    |> validate_required([:status])
  end

  defp validate_origin(changeset) do
    case get_field(changeset, :origin) do
      :deterministic -> validate_required(changeset, [:rule_id, :rule_version])
      :expert -> validate_required(changeset, [:created_by_user_id])
      _other -> changeset
    end
  end
end
