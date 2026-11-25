defmodule Contexla.Applications.ContentIntegrityMonitor.Monitor do
  @moduledoc "One configured recurring content-integrity question."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_monitors" do
    field(:application_instance_id, :binary_id)
    field(:name, :string)
    field(:entity_key, :string)
    field(:status, Ecto.Enum, values: [:active, :paused], default: :active)
    has_many(:sources, Contexla.Applications.ContentIntegrityMonitor.Source)
    has_many(:facts, Contexla.Applications.ContentIntegrityMonitor.FactDefinition)
    timestamps(type: :utc_datetime)
  end

  def changeset(monitor, attrs) do
    monitor
    |> cast(attrs, [:application_instance_id, :name, :entity_key, :status])
    |> validate_required([:application_instance_id, :name, :entity_key, :status])
    |> unique_constraint([:application_instance_id, :name])
  end
end
