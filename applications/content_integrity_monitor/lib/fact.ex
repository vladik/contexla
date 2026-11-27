defmodule Contexla.Applications.ContentIntegrityMonitor.Fact do
  @moduledoc "A named, typed field tracked across all sources for every entity."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_facts" do
    field(:key, :string)
    field(:name, :string)
    field(:description, :string)
    field(:comparison_type, Ecto.Enum, values: [:text, :text_case_insensitive, :numeric, :date], default: :text)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    has_many(:target_fact_profiles, Contexla.Applications.ContentIntegrityMonitor.TargetFactProfile)
    timestamps(type: :utc_datetime)
  end

  def changeset(fact, attrs) do
    fact
    |> cast(attrs, [:monitor_id, :key, :name, :description, :comparison_type])
    |> validate_required([:monitor_id, :key, :name])
    |> validate_format(:key, ~r/^[a-z0-9_-]+$/,
      message: "can only contain lowercase letters, numbers, hyphens and underscores"
    )
    |> unique_constraint([:monitor_id, :key])
  end
end
