defmodule Contexla.Repo.Migrations.CreateApplicationOperationInvocations do
  use Ecto.Migration

  def change do
    create table(:application_operation_invocations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :application_instance_id,
          references(:application_instances, type: :binary_id, on_delete: :restrict),
          null: false

      add :invoked_by_user_id, references(:users, type: :binary_id, on_delete: :restrict),
        null: false

      add :approved_by_user_id, references(:users, type: :binary_id, on_delete: :restrict)

      add :application_id, :string, null: false
      add :application_version, :string, null: false
      add :operation_id, :string, null: false
      add :status, :string, null: false
      add :approval_required, :boolean, null: false, default: false
      add :approved_at, :utc_datetime
      add :input, :map, null: false, default: %{}
      add :output, :map
      add :error, :map
      add :run_id, :string
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:application_operation_invocations, [:application_instance_id])
    create index(:application_operation_invocations, [:operation_id])
    create index(:application_operation_invocations, [:status])
    create index(:application_operation_invocations, [:run_id])
  end
end
