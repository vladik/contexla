defmodule Contexla.Platform.Tools.Invocation do
  @moduledoc "Durable record of one requested Tool execution."

  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Platform.Accounts.User
  alias Contexla.Platform.Applications.ApplicationInstance
  alias Contexla.Platform.Artifacts.Artifact
  alias Contexla.Platform.Tools.Tool

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "tool_invocations" do
    field :status, Ecto.Enum,
      values: [:pending, :running, :succeeded, :failed, :timed_out, :cancelled]

    field :parent_run_id, :binary_id
    field :input, :map
    field :output, :map
    field :error, :map
    field :requested_at, :utc_datetime
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :tool, Tool
    belongs_to :input_artifact, Artifact
    belongs_to :application_instance, ApplicationInstance
    belongs_to :invoked_by_user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def request_changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [
      :tool_id,
      :input_artifact_id,
      :application_instance_id,
      :invoked_by_user_id,
      :parent_run_id,
      :status,
      :input,
      :requested_at
    ])
    |> validate_required([
      :tool_id,
      :input_artifact_id,
      :application_instance_id,
      :invoked_by_user_id,
      :status,
      :input,
      :requested_at
    ])
    |> foreign_key_constraint(:tool_id)
  end

  def transition_changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [:status, :output, :error, :started_at, :completed_at])
    |> validate_required([:status])
  end
end
