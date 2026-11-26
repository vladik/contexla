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
    field(:format, Ecto.Enum, values: [:json, :html, :csv, :manual])
    field(:fetch_strategy, Ecto.Enum, values: [:fetch_entity, :fetch_all_entities], default: :fetch_entity)
    field(:url, :string)
    field(:array_path, :string)
    field(:id_field, :string, default: "id")
    field(:mappings, :map, default: %{})
    field(:static_ids, :string)
    field(:sort_order, :integer, default: 0)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    timestamps(type: :utc_datetime)
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [
      :monitor_id,
      :key,
      :name,
      :role,
      :format,
      :fetch_strategy,
      :url,
      :array_path,
      :id_field,
      :mappings,
      :static_ids,
      :sort_order
    ])
    |> validate_required([:monitor_id, :key, :name, :role, :format, :mappings])
    |> unique_constraint([:monitor_id, :key])
  end
end
