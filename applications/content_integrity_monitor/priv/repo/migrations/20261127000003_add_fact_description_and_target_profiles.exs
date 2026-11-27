defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddFactDescriptionAndTargetProfiles do
  use Ecto.Migration

  def change do
    alter table(:integrity_facts) do
      add :description, :text
    end

    create table(:integrity_target_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :source_id,
          references(:integrity_sources, type: :binary_id, on_delete: :delete_all),
          null: false

      add :fact_id,
          references(:integrity_facts, type: :binary_id, on_delete: :delete_all),
          null: false

      add :expected, :string, null: false, default: "required"
      add :comparison_type, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:integrity_target_profiles, [:source_id, :fact_id])
    create index(:integrity_target_profiles, [:source_id])
    create index(:integrity_target_profiles, [:fact_id])
  end
end
