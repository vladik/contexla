defmodule Contexla.Platform.Artifacts.Artifact do
  @moduledoc """
  Immutable metadata for a file retained by Contexla.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Contexla.Platform.Accounts.User
  alias Contexla.Platform.Applications.ApplicationInstance

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "artifacts" do
    field :kind, :string
    field :source_type, :string
    field :filename, :string
    field :media_type, :string
    field :sha256, :string
    field :byte_size, :integer
    field :storage_key, :string
    field :metadata, :map, default: %{}

    belongs_to :application_instance, ApplicationInstance
    belongs_to :created_by_user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def create_changeset(artifact, attrs, %ApplicationInstance{} = instance, %User{} = user) do
    artifact
    |> cast(attrs, [
      :kind,
      :source_type,
      :filename,
      :media_type,
      :sha256,
      :byte_size,
      :storage_key,
      :metadata
    ])
    |> put_change(:application_instance_id, instance.id)
    |> put_change(:created_by_user_id, user.id)
    |> validate_required([
      :application_instance_id,
      :created_by_user_id,
      :kind,
      :source_type,
      :filename,
      :media_type,
      :sha256,
      :byte_size,
      :storage_key,
      :metadata
    ])
    |> validate_format(:sha256, ~r/^[0-9a-f]{64}$/)
    |> validate_number(:byte_size, greater_than_or_equal_to: 0)
    |> validate_length(:filename, min: 1, max: 255)
    |> unique_constraint([:application_instance_id, :kind, :sha256])
    |> foreign_key_constraint(:application_instance_id)
    |> foreign_key_constraint(:created_by_user_id)
  end
end
