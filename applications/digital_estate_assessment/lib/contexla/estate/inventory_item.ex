defmodule Contexla.Estate.InventoryItem do
  @moduledoc "One typed normalized item within an Assessment Snapshot."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_inventory_items" do
    field(:snapshot_id, :binary_id)
    field(:evidence_item_id, :binary_id)
    field(:kind, :string)
    field(:external_key, :string)
    field(:name, :string)
    field(:attributes, :map, default: %{})
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:snapshot_id, :evidence_item_id, :kind, :external_key, :name, :attributes])
    |> validate_required([:snapshot_id, :kind, :external_key, :name, :attributes])
    |> unique_constraint([:snapshot_id, :kind, :external_key])
  end
end
