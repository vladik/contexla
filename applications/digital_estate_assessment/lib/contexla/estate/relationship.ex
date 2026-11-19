defmodule Contexla.Estate.Relationship do
  @moduledoc "A typed relationship between normalized inventory items."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @schema_prefix "contexla_estate"
  schema "estate_relationships" do
    field(:snapshot_id, :binary_id)
    field(:from_inventory_item_id, :binary_id)
    field(:to_inventory_item_id, :binary_id)
    field(:evidence_item_id, :binary_id)
    field(:kind, :string)
    field(:attributes, :map, default: %{})
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [
      :snapshot_id,
      :from_inventory_item_id,
      :to_inventory_item_id,
      :evidence_item_id,
      :kind,
      :attributes
    ])
    |> validate_required([
      :snapshot_id,
      :from_inventory_item_id,
      :to_inventory_item_id,
      :kind,
      :attributes
    ])
  end
end
