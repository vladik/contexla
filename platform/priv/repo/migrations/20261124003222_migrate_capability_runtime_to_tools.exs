defmodule Contexla.Platform.Repo.Migrations.MigrateCapabilityRuntimeToTools do
  use Ecto.Migration

  def up do
    create table(:tools, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :version, :string, null: false
      add :name, :string, null: false
      add :purpose, :text, null: false
      add :runtime, :string, null: false
      add :entrypoint, :string, null: false
      add :input_schema, :map, null: false
      add :output_schema, :map, null: false
      add :error_schema, :map, null: false, default: %{}
      add :dependency_spec, :map, null: false, default: %{}
      add :permissions, {:array, :string}, null: false, default: []
      add :resource_limits, :map, null: false, default: %{}
      add :timeout_ms, :integer, null: false
      add :determinism, :string, null: false
      add :side_effects, :string, null: false
      add :idempotency, :string, null: false
      add :worker_profile, :string, null: false
      add :platform, :string, null: false
      add :architectures, {:array, :string}, null: false, default: []
      add :features, {:array, :string}, null: false, default: []
      add :package_sha256, :string
      add :owner_scope, :string, null: false
      add :owner_key, :string, null: false
      add :definition_digest, :string, null: false
      add :status, :string, null: false, default: "active"
      add :package_artifact_id, references(:artifacts, type: :binary_id, on_delete: :restrict)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tools, [:key, :version])
    create index(:tools, [:owner_scope, :owner_key])

    create table(:tool_invocations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tool_id, references(:tools, type: :binary_id, on_delete: :restrict), null: false

      add :input_artifact_id,
          references(:artifacts, type: :binary_id, on_delete: :restrict)

      add :application_instance_id,
          references(:application_instances, type: :binary_id, on_delete: :restrict)

      add :invoked_by_user_id, references(:users, type: :binary_id, on_delete: :restrict),
        null: false

      add :parent_run_id, :binary_id
      add :status, :string, null: false
      add :input, :map, null: false
      add :output, :map
      add :error, :map
      add :requested_at, :utc_datetime, null: false
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:tool_invocations, [:application_instance_id])
    create index(:tool_invocations, [:tool_id])
    create index(:tool_invocations, [:parent_run_id])
    create index(:tool_invocations, [:status])

    flush()

    execute("""
    INSERT INTO tools (
      id, key, version, name, purpose, runtime, entrypoint,
      input_schema, output_schema, error_schema, dependency_spec,
      permissions, resource_limits, timeout_ms, determinism, side_effects,
      idempotency, worker_profile, platform, architectures, features,
      package_sha256, owner_scope, owner_key, definition_digest, status,
      package_artifact_id, inserted_at, updated_at
    )
    SELECT
      p.id, p.key, p.version, c.name, c.purpose, p.runtime, p.entrypoint,
      c.input_schema, c.output_schema, c.error_schema, p.dependency_spec,
      p.requested_permissions, p.resource_limits, p.timeout_ms,
      c.determinism, c.side_effects, c.idempotency,
      'legacy_tools', 'any', ARRAY[]::varchar[], ARRAY[]::varchar[],
      NULL, p.owner_scope, p.owner_key, p.definition_digest, 'retired',
      p.package_artifact_id, p.inserted_at, p.updated_at
    FROM processors p
    INNER JOIN capabilities c ON c.id = p.capability_id
    """)

    execute("""
    INSERT INTO tool_invocations (
      id, tool_id, input_artifact_id, application_instance_id,
      invoked_by_user_id, parent_run_id, status, input, output, error,
      requested_at, started_at, completed_at, inserted_at
    )
    SELECT
      i.id, i.processor_id, NULL, i.application_instance_id,
      i.invoked_by_user_id, NULL, i.status, i.input, i.output, i.error,
      i.started_at, i.started_at, i.completed_at, i.inserted_at
    FROM capability_invocations i
    """)

    drop table(:capability_invocations)
    drop table(:capability_bindings)
    drop table(:processors)
    drop table(:capabilities)
  end

  def down do
    raise "the unified Tool migration is intentionally irreversible"
  end
end
