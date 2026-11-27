defmodule Contexla.Platform.Connections.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Platform.Connections.EncryptedMap

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connections" do
    field :name, :string
    field :description, :string
    field :adapter_key, :string
    field :base_url, :string
    field :settings, :map, default: %{}
    field :credentials, EncryptedMap, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:name, :description, :adapter_key, :base_url, :settings, :credentials])
    |> validate_required([:name, :adapter_key, :base_url])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 500)
    |> validate_format(:base_url, ~r/^https?:\/\/.+/, message: "must be a valid URL")
    |> unique_constraint(:name)
  end
end
