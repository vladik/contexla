defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.ExtendCollectionModel do
  use Ecto.Migration

  def change do
    alter table(:integrity_monitors) do
      add :collection_key, :string
      add :scope_source_id, :binary_id
      add :cron_expression, :string
    end

    alter table(:integrity_sources) do
      add :fetch_strategy, :string, null: false, default: "per_item"
      add :item_url_template, :text
      add :scope_key_path, :string
    end

    alter table(:integrity_source_checks) do
      add :entity_id, :string
    end

    drop unique_index(:integrity_evidence, [:run_id, :source_id])

    alter table(:integrity_evidence) do
      add :entity_id, :string
    end

    create unique_index(:integrity_evidence, [:run_id, :source_id, :entity_id])

    drop unique_index(:integrity_observations, [:run_id, :source_id, :fact_definition_id])

    alter table(:integrity_observations) do
      add :entity_id, :string
    end

    create unique_index(:integrity_observations, [:run_id, :source_id, :fact_definition_id, :entity_id])

    alter table(:integrity_issues) do
      add :entity_id, :string
    end

    create index(:integrity_issues, [:entity_id],
      where: "entity_id IS NOT NULL",
      name: "integrity_issues_entity_id_index"
    )

    create table(:integrity_schedule_windows, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :monitor_id,
          references(:integrity_monitors, type: :binary_id, on_delete: :delete_all),
          null: false

      add :label, :string
      add :rrule, :text, null: false
      add :duration_seconds, :integer, null: false
      timestamps(type: :utc_datetime)
    end

    create index(:integrity_schedule_windows, [:monitor_id])
  end
end
