defmodule Contexla.Platform.Repo.Migrations.CreateCapabilityRuntime do
  use Ecto.Migration

  def change do
    create table(:capabilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :contract_version, :string, null: false
      add :name, :string, null: false
      add :purpose, :text, null: false
      add :input_schema, :map, null: false
      add :output_schema, :map, null: false
      add :error_schema, :map, null: false, default: %{}
      add :permissions, {:array, :string}, null: false, default: []
      add :determinism, :string, null: false
      add :side_effects, :string, null: false
      add :idempotency, :string, null: false
      add :owner_scope, :string, null: false
      add :owner_key, :string, null: false
      add :definition_digest, :string, null: false
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:capabilities, [:key, :contract_version])

    create table(:processors, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :capability_id, references(:capabilities, type: :binary_id, on_delete: :restrict),
        null: false

      add :key, :string, null: false
      add :version, :string, null: false
      add :runtime, :string, null: false
      add :entrypoint, :string, null: false
      add :config_schema, :map, null: false, default: %{}
      add :requested_permissions, {:array, :string}, null: false, default: []
      add :resource_limits, :map, null: false, default: %{}
      add :timeout_ms, :integer, null: false
      add :owner_scope, :string, null: false
      add :owner_key, :string, null: false
      add :definition_digest, :string, null: false
      add :status, :string, null: false, default: "active"
      add :package_artifact_id, references(:artifacts, type: :binary_id, on_delete: :restrict)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:processors, [:key, :version])
    create index(:processors, [:capability_id])

    create table(:capability_bindings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :capability_id, references(:capabilities, type: :binary_id, on_delete: :restrict),
        null: false

      add :processor_id, references(:processors, type: :binary_id, on_delete: :restrict),
        null: false

      add :scope, :string, null: false
      add :scope_key, :string, null: false
      add :config, :map, null: false, default: %{}
      add :granted_permissions, {:array, :string}, null: false, default: []
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:capability_bindings, [:capability_id, :scope, :scope_key])
    create index(:capability_bindings, [:processor_id])

    create table(:capability_invocations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :capability_id, references(:capabilities, type: :binary_id, on_delete: :restrict),
        null: false

      add :processor_id, references(:processors, type: :binary_id, on_delete: :restrict),
        null: false

      add :binding_id, references(:capability_bindings, type: :binary_id, on_delete: :restrict),
        null: false

      add :application_instance_id,
          references(:application_instances, type: :binary_id, on_delete: :restrict)

      add :invoked_by_user_id, references(:users, type: :binary_id, on_delete: :restrict),
        null: false

      add :status, :string, null: false
      add :input, :map, null: false
      add :output, :map
      add :error, :map
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:capability_invocations, [:application_instance_id])
    create index(:capability_invocations, [:capability_id])
    create index(:capability_invocations, [:processor_id])
  end
end
