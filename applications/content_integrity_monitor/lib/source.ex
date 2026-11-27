defmodule Contexla.Applications.ContentIntegrityMonitor.Source do
  @moduledoc "One authoritative or delivered content representation."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_sources" do
    field(:key, :string)
    field(:name, :string)
    field(:role, Ecto.Enum, values: [:scope, :source, :target])
    field(:connection_id, :binary_id)
    field(:fetch_strategy, Ecto.Enum, values: [:fetch_entity, :fetch_all_entities], default: :fetch_entity)
    field(:url, :string)
    field(:array_path, :string)
    field(:ref_field, :string, default: "id")
    field(:scope_ref_field, :string)
    field(:mappings, :map, default: %{})
    field(:static_refs, :string)
    field(:sort_order, :integer, default: 0)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    has_many(:target_fact_profiles, Contexla.Applications.ContentIntegrityMonitor.TargetFactProfile,
      foreign_key: :source_id
    )
    timestamps(type: :utc_datetime)
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [
      :monitor_id,
      :key,
      :name,
      :role,
      :connection_id,
      :fetch_strategy,
      :url,
      :array_path,
      :ref_field,
      :scope_ref_field,
      :mappings,
      :static_refs,
      :sort_order
    ])
    |> validate_required([:monitor_id, :key, :name, :role, :mappings])
    |> unique_constraint([:monitor_id, :key])
  end
end
