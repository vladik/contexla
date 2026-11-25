defmodule Contexla.Platform.Tools.Tool do
  @moduledoc "Persisted registration of one immutable Tool version."

  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Platform.Artifacts.Artifact

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "tools" do
    field :key, :string
    field :version, :string
    field :name, :string
    field :purpose, :string
    field :runtime, Ecto.Enum, values: [:native, :python, :cli, :node]
    field :entrypoint, :string
    field :input_schema, :map
    field :output_schema, :map
    field :error_schema, :map, default: %{}
    field :dependency_spec, :map, default: %{}
    field :permissions, {:array, :string}, default: []
    field :resource_limits, :map, default: %{}
    field :timeout_ms, :integer
    field :determinism, Ecto.Enum, values: [:deterministic, :nondeterministic]
    field :side_effects, Ecto.Enum, values: [:none, :read, :write, :external]
    field :idempotency, Ecto.Enum, values: [:not_applicable, :idempotent, :non_idempotent]
    field :worker_profile, :string
    field :platform, :string
    field :architectures, {:array, :string}, default: []
    field :features, {:array, :string}, default: []
    field :package_sha256, :string
    field :owner_scope, Ecto.Enum, values: [:platform, :application, :instance]
    field :owner_key, :string
    field :definition_digest, :string
    field :status, Ecto.Enum, values: [:active, :disabled, :retired], default: :active

    belongs_to :package_artifact, Artifact

    timestamps(type: :utc_datetime)
  end

  def changeset(tool, attrs) do
    tool
    |> cast(attrs, [
      :key,
      :version,
      :name,
      :purpose,
      :runtime,
      :entrypoint,
      :input_schema,
      :output_schema,
      :error_schema,
      :dependency_spec,
      :permissions,
      :resource_limits,
      :timeout_ms,
      :determinism,
      :side_effects,
      :idempotency,
      :worker_profile,
      :platform,
      :architectures,
      :features,
      :package_sha256,
      :owner_scope,
      :owner_key,
      :definition_digest,
      :status,
      :package_artifact_id
    ])
    |> validate_required([
      :key,
      :version,
      :name,
      :purpose,
      :runtime,
      :entrypoint,
      :input_schema,
      :output_schema,
      :resource_limits,
      :timeout_ms,
      :determinism,
      :side_effects,
      :idempotency,
      :worker_profile,
      :platform,
      :owner_scope,
      :owner_key,
      :definition_digest,
      :status
    ])
    |> validate_number(:timeout_ms, greater_than: 0)
    |> unique_constraint([:key, :version])
  end
end
