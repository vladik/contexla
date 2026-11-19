defmodule Contexla.Capabilities.Processor do
  @moduledoc "Persisted registration of a concrete Capability implementation."

  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Artifacts.Artifact
  alias Contexla.Capabilities.Contract

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "processors" do
    field :key, :string
    field :version, :string
    field :runtime, Ecto.Enum, values: [:native, :python, :cli, :http]
    field :entrypoint, :string
    field :dependency_spec, :map, default: %{}
    field :config_schema, :map, default: %{}
    field :requested_permissions, {:array, :string}, default: []
    field :resource_limits, :map, default: %{}
    field :timeout_ms, :integer
    field :owner_scope, Ecto.Enum, values: [:platform, :application, :instance]
    field :owner_key, :string
    field :definition_digest, :string
    field :status, Ecto.Enum, values: [:active, :disabled, :retired], default: :active

    belongs_to :capability, Contract
    belongs_to :package_artifact, Artifact

    timestamps(type: :utc_datetime)
  end

  def changeset(processor, attrs) do
    processor
    |> cast(attrs, [
      :capability_id,
      :key,
      :version,
      :runtime,
      :entrypoint,
      :dependency_spec,
      :config_schema,
      :requested_permissions,
      :resource_limits,
      :timeout_ms,
      :owner_scope,
      :owner_key,
      :definition_digest,
      :status,
      :package_artifact_id
    ])
    |> validate_required([
      :capability_id,
      :key,
      :version,
      :runtime,
      :entrypoint,
      :dependency_spec,
      :config_schema,
      :requested_permissions,
      :resource_limits,
      :timeout_ms,
      :owner_scope,
      :owner_key,
      :definition_digest,
      :status
    ])
    |> validate_number(:timeout_ms, greater_than: 0)
    |> unique_constraint([:key, :version])
    |> foreign_key_constraint(:capability_id)
  end
end
