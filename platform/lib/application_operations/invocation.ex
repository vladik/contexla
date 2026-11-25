defmodule Contexla.Platform.ApplicationOperations.Invocation do
  @moduledoc "One auditable invocation of an Application-declared Operation."

  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Platform.Accounts.User
  alias Contexla.Platform.Applications.ApplicationInstance

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "application_operation_invocations" do
    field :application_id, :string
    field :application_version, :string
    field :operation_id, :string
    field :status, Ecto.Enum, values: [:running, :succeeded, :failed]
    field :approval_required, :boolean, default: false
    field :approved_at, :utc_datetime
    field :input, :map, default: %{}
    field :output, :map
    field :error, :map
    field :run_id, :string
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :application_instance, ApplicationInstance
    belongs_to :invoked_by_user, User
    belongs_to :approved_by_user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def start_changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [
      :application_instance_id,
      :invoked_by_user_id,
      :approved_by_user_id,
      :application_id,
      :application_version,
      :operation_id,
      :status,
      :approval_required,
      :approved_at,
      :input,
      :started_at
    ])
    |> validate_required([
      :application_instance_id,
      :invoked_by_user_id,
      :application_id,
      :application_version,
      :operation_id,
      :status,
      :approval_required,
      :input,
      :started_at
    ])
    |> foreign_key_constraint(:application_instance_id)
    |> foreign_key_constraint(:invoked_by_user_id)
    |> foreign_key_constraint(:approved_by_user_id)
  end

  def complete_changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [:status, :output, :error, :run_id, :completed_at])
    |> validate_required([:status, :completed_at])
  end
end
