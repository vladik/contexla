defmodule Contexla.Capabilities.Contract do
  @moduledoc "Persisted, immutable version of a Capability contract."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "capabilities" do
    field :key, :string
    field :contract_version, :string
    field :name, :string
    field :purpose, :string
    field :input_schema, :map
    field :output_schema, :map
    field :error_schema, :map, default: %{}
    field :permissions, {:array, :string}, default: []
    field :determinism, Ecto.Enum, values: [:deterministic, :nondeterministic]
    field :side_effects, Ecto.Enum, values: [:none, :read, :write, :external]
    field :idempotency, Ecto.Enum, values: [:not_applicable, :idempotent, :non_idempotent]
    field :owner_scope, Ecto.Enum, values: [:platform, :application, :instance]
    field :owner_key, :string
    field :definition_digest, :string
    field :status, Ecto.Enum, values: [:active, :disabled, :retired], default: :active

    timestamps(type: :utc_datetime)
  end

  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [
      :key,
      :contract_version,
      :name,
      :purpose,
      :input_schema,
      :output_schema,
      :error_schema,
      :permissions,
      :determinism,
      :side_effects,
      :idempotency,
      :owner_scope,
      :owner_key,
      :definition_digest,
      :status
    ])
    |> validate_required([
      :key,
      :contract_version,
      :name,
      :purpose,
      :input_schema,
      :output_schema,
      :determinism,
      :side_effects,
      :idempotency,
      :owner_scope,
      :owner_key,
      :definition_digest,
      :status
    ])
    |> unique_constraint([:key, :contract_version])
  end
end
