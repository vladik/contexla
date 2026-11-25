defmodule Contexla.Platform.AuditEvents.Event do
  @moduledoc "One append-only record of a security or lifecycle-relevant platform action."

  use Ecto.Schema

  import Ecto.Changeset

  alias Contexla.Platform.Accounts.User
  alias Contexla.Platform.Applications.ApplicationInstance

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "audit_events" do
    field :sequence, :integer, read_after_writes: true
    field :action, :string
    field :subject_type, :string
    field :subject_id, :string
    field :metadata, :map, default: %{}

    belongs_to :actor_user, User
    belongs_to :application_instance, ApplicationInstance

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def create_changeset(event, attrs) do
    event
    |> cast(attrs, [
      :action,
      :subject_type,
      :subject_id,
      :metadata,
      :actor_user_id,
      :application_instance_id
    ])
    |> validate_required([:action, :subject_type, :subject_id, :metadata, :actor_user_id])
    |> validate_format(:action, ~r/^[a-z][a-z0-9_.-]+$/)
    |> validate_length(:action, max: 120)
    |> validate_length(:subject_type, max: 80)
    |> validate_length(:subject_id, max: 255)
    |> foreign_key_constraint(:actor_user_id)
    |> foreign_key_constraint(:application_instance_id)
  end
end
