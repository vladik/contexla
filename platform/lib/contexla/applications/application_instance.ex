defmodule Contexla.Applications.ApplicationInstance do
  @moduledoc """
  A configured use of one installed Contexla Application.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Contexla.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "application_instances" do
    field :application_id, :string
    field :application_version, :string
    field :name, :string
    field :description, :string
    field :icon, :string
    field :status, Ecto.Enum, values: [:draft, :active, :archived], default: :draft
    field :config, :map, default: %{}

    belongs_to :created_by_user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(instance, attrs, definition, %User{} = user) do
    instance
    |> cast(attrs, [:name, :description, :icon, :config])
    |> normalize_icon()
    |> put_change(:application_id, definition.id)
    |> put_change(:application_version, definition.version)
    |> put_change(:created_by_user_id, user.id)
    |> validate_required([
      :application_id,
      :application_version,
      :name,
      :status,
      :config,
      :created_by_user_id
    ])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 500)
    |> validate_format(:name, ~r/\S/, message: "must contain a visible character")
    |> unique_constraint([:application_id, :name])
    |> foreign_key_constraint(:created_by_user_id)
  end

  def status_changeset(instance, status) do
    instance
    |> change(status: status)
    |> validate_required([:status])
  end

  def settings_changeset(instance, attrs) do
    instance
    |> cast(attrs, [:name, :description, :icon])
    |> normalize_icon()
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 500)
    |> validate_format(:name, ~r/\S/, message: "must contain a visible character")
    |> validate_format(:icon, ~r/^hero-[a-z0-9-]+$/)
    |> unique_constraint([:application_id, :name])
  end

  def config_changeset(instance, config) when is_map(config) do
    change(instance, config: config)
  end

  defp normalize_icon(changeset) do
    case get_change(changeset, :icon) do
      "" -> put_change(changeset, :icon, nil)
      _icon -> changeset
    end
  end
end
