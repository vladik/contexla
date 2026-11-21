defmodule Contexla.Repo.Migrations.CreateAuditEvents do
  use Ecto.Migration

  def change do
    create table(:audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false
      add :subject_type, :string, null: false
      add :subject_id, :string, null: false
      add :metadata, :map, null: false, default: %{}

      add :actor_user_id, references(:users, type: :binary_id, on_delete: :restrict), null: false

      add :application_instance_id,
          references(:application_instances, type: :binary_id, on_delete: :restrict)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_events, [:application_instance_id, :inserted_at])
    create index(:audit_events, [:actor_user_id, :inserted_at])
    create index(:audit_events, [:action, :inserted_at])
  end
end
