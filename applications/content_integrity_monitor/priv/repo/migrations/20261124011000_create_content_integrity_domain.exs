defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.CreateContentIntegrityDomain do
  use Ecto.Migration

  def change do
    create table(:integrity_monitors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :application_instance_id, :binary_id, null: false
      add :name, :string, null: false
      add :entity_key, :string, null: false
      add :status, :string, null: false, default: "active"
      timestamps(type: :utc_datetime)
    end

    create index(:integrity_monitors, [:application_instance_id])
    create unique_index(:integrity_monitors, [:application_instance_id, :name])

    create table(:integrity_sources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :monitor_id, references(:integrity_monitors, type: :binary_id, on_delete: :delete_all), null: false
      add :key, :string, null: false
      add :name, :string, null: false
      add :role, :string, null: false
      add :format, :string, null: false
      add :url, :text, null: false
      add :mappings, :map, null: false, default: %{}
      add :allowed_delay_seconds, :integer, null: false, default: 0
      timestamps(type: :utc_datetime)
    end

    create unique_index(:integrity_sources, [:monitor_id, :key])

    create table(:integrity_fact_definitions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :monitor_id, references(:integrity_monitors, type: :binary_id, on_delete: :delete_all), null: false
      add :key, :string, null: false
      add :name, :string, null: false
      add :required, :boolean, null: false, default: true
      timestamps(type: :utc_datetime)
    end

    create unique_index(:integrity_fact_definitions, [:monitor_id, :key])

    create table(:integrity_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :monitor_id, references(:integrity_monitors, type: :binary_id, on_delete: :restrict), null: false
      add :application_instance_id, :binary_id, null: false
      add :initiated_by_user_id, :binary_id, null: false
      add :status, :string, null: false
      add :summary, :map, null: false, default: %{}
      add :error, :map
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create index(:integrity_runs, [:application_instance_id, :inserted_at])
    create index(:integrity_runs, [:monitor_id, :inserted_at])

    create table(:integrity_source_checks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:integrity_runs, type: :binary_id, on_delete: :delete_all), null: false
      add :source_id, references(:integrity_sources, type: :binary_id, on_delete: :restrict), null: false
      add :status, :string, null: false
      add :tool_invocation_id, :binary_id
      add :http_status, :integer
      add :fetched_at, :utc_datetime
      add :response_sha256, :string
      add :media_type, :string
      add :excerpt, :text
      add :error, :map
      timestamps(type: :utc_datetime)
    end

    create unique_index(:integrity_source_checks, [:run_id, :source_id])
    create index(:integrity_source_checks, [:tool_invocation_id])

    create table(:integrity_evidence, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:integrity_runs, type: :binary_id, on_delete: :delete_all), null: false
      add :source_id, references(:integrity_sources, type: :binary_id, on_delete: :restrict), null: false
      add :tool_invocation_id, :binary_id
      add :response_sha256, :string, null: false
      add :media_type, :string, null: false
      add :excerpt, :text, null: false
      add :values, :map, null: false, default: %{}
      add :observed_at, :utc_datetime, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:integrity_evidence, [:run_id, :source_id])

    create table(:integrity_observations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:integrity_runs, type: :binary_id, on_delete: :delete_all), null: false
      add :source_id, references(:integrity_sources, type: :binary_id, on_delete: :restrict), null: false
      add :fact_definition_id, references(:integrity_fact_definitions, type: :binary_id, on_delete: :restrict), null: false
      add :evidence_id, references(:integrity_evidence, type: :binary_id, on_delete: :restrict)
      add :raw_value, :text
      add :normalized_value, :text
      add :state, :string, null: false
      add :source_updated_at, :utc_datetime
      add :observed_at, :utc_datetime, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:integrity_observations, [:run_id, :source_id, :fact_definition_id])

    create table(:integrity_issues, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :monitor_id, references(:integrity_monitors, type: :binary_id, on_delete: :delete_all), null: false
      add :source_id, references(:integrity_sources, type: :binary_id, on_delete: :restrict), null: false
      add :fact_definition_id, references(:integrity_fact_definitions, type: :binary_id, on_delete: :restrict), null: false
      add :current_observation_id, references(:integrity_observations, type: :binary_id, on_delete: :nilify_all)
      add :kind, :string, null: false
      add :status, :string, null: false, default: "open"
      add :summary, :text, null: false
      add :occurrence_count, :integer, null: false, default: 1
      add :first_seen_at, :utc_datetime, null: false
      add :last_seen_at, :utc_datetime, null: false
      add :resolved_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create index(:integrity_issues, [:monitor_id, :status])
    create index(:integrity_issues, [:source_id, :fact_definition_id])
  end
end
