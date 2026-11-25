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
    field(:role, Ecto.Enum, values: [:authority, :representation])
    field(:format, Ecto.Enum, values: [:json, :html])
    field(:url, :string)
    field(:mappings, :map, default: %{})
    field(:allowed_delay_seconds, :integer, default: 0)
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
      :url,
      :mappings,
      :allowed_delay_seconds
    ])
    |> validate_required([:monitor_id, :key, :name, :role, :format, :url, :mappings])
    |> validate_number(:allowed_delay_seconds, greater_than_or_equal_to: 0)
    |> unique_constraint([:monitor_id, :key])
  end
end
