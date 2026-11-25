defmodule Contexla.Applications.ContentIntegrityMonitor.FactDefinition do
  @moduledoc "A fact and deterministic comparison policy owned by a Monitor."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_fact_definitions" do
    field(:key, :string)
    field(:name, :string)
    field(:required, :boolean, default: true)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    timestamps(type: :utc_datetime)
  end

  def changeset(fact, attrs) do
    fact
    |> cast(attrs, [:monitor_id, :key, :name, :required])
    |> validate_required([:monitor_id, :key, :name, :required])
    |> unique_constraint([:monitor_id, :key])
  end
end
