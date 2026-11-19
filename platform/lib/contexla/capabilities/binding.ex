defmodule Contexla.Capabilities.Binding do
  @moduledoc "Selects and configures a Processor for a Capability scope."

  use Ecto.Schema
  import Ecto.Changeset

  alias Contexla.Capabilities.{Contract, Processor}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "capability_bindings" do
    field :scope, Ecto.Enum, values: [:platform, :application, :instance]
    field :scope_key, :string
    field :config, :map, default: %{}
    field :granted_permissions, {:array, :string}, default: []
    field :status, Ecto.Enum, values: [:active, :disabled], default: :active

    belongs_to :capability, Contract
    belongs_to :processor, Processor

    timestamps(type: :utc_datetime)
  end

  def changeset(binding, attrs) do
    binding
    |> cast(attrs, [
      :capability_id,
      :processor_id,
      :scope,
      :scope_key,
      :config,
      :granted_permissions,
      :status
    ])
    |> validate_required([
      :capability_id,
      :processor_id,
      :scope,
      :scope_key,
      :config,
      :granted_permissions,
      :status
    ])
    |> unique_constraint([:capability_id, :scope, :scope_key])
    |> foreign_key_constraint(:capability_id)
    |> foreign_key_constraint(:processor_id)
  end
end
