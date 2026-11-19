defmodule Contexla.Capabilities.Invocation do
  @moduledoc "One auditable execution of a Capability through a selected Processor."

  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Accounts.User
  alias Contexla.Applications.ApplicationInstance
  alias Contexla.Capabilities.{Binding, Contract, Processor}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "capability_invocations" do
    field :status, Ecto.Enum, values: [:running, :succeeded, :failed, :timed_out]
    field :input, :map
    field :output, :map
    field :error, :map
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :capability, Contract
    belongs_to :processor, Processor
    belongs_to :binding, Binding
    belongs_to :application_instance, ApplicationInstance
    belongs_to :invoked_by_user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def start_changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [
      :capability_id,
      :processor_id,
      :binding_id,
      :application_instance_id,
      :invoked_by_user_id,
      :status,
      :input,
      :started_at
    ])
    |> validate_required([
      :capability_id,
      :processor_id,
      :binding_id,
      :invoked_by_user_id,
      :status,
      :input,
      :started_at
    ])
  end

  def complete_changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [:status, :output, :error, :completed_at])
    |> validate_required([:status, :completed_at])
  end
end
