defmodule Contexla.Applications.DigitalEstateAssessment.Migrations.CreateEstateAssessmentDomain do
  use Ecto.Migration

  def change do
    create table(:estate_assessment_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :application_instance_id,
          references(:application_instances,
            type: :binary_id,
            on_delete: :restrict,
            prefix: "public"
          ),
          null: false

      add :source_artifact_id,
          references(:artifacts, type: :binary_id, on_delete: :restrict, prefix: "public"),
        null: false

      add :initiated_by_user_id,
          references(:users, type: :binary_id, on_delete: :restrict, prefix: "public"),
        null: false

      add :status, :string, null: false
      add :adapter_id, :string, null: false
      add :adapter_version, :string, null: false
      add :rule_set_version, :string, null: false
      add :summary, :map, null: false, default: %{}
      add :error, :map
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:estate_assessment_runs, [:application_instance_id])
    create index(:estate_assessment_runs, [:source_artifact_id])
    create index(:estate_assessment_runs, [:status])

    create table(:estate_evidence_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :assessment_run_id,
          references(:estate_assessment_runs, type: :binary_id, on_delete: :delete_all),
          null: false

      add :artifact_id,
          references(:artifacts, type: :binary_id, on_delete: :restrict, prefix: "public"),
        null: false

      add :path, :string, null: false
      add :kind, :string, null: false
      add :media_type, :string, null: false
      add :sha256, :string, null: false
      add :byte_size, :bigint, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:estate_evidence_items, [:assessment_run_id, :path])

    create table(:estate_snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :assessment_run_id,
          references(:estate_assessment_runs, type: :binary_id, on_delete: :delete_all),
          null: false

      add :target_key, :string, null: false
      add :adapter_id, :string, null: false
      add :adapter_version, :string, null: false
      add :collected_at, :utc_datetime, null: false
      add :limitations, {:array, :string}, null: false, default: []

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:estate_snapshots, [:assessment_run_id, :target_key])

    create table(:estate_inventory_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :snapshot_id, references(:estate_snapshots, type: :binary_id, on_delete: :delete_all),
        null: false

      add :evidence_item_id,
          references(:estate_evidence_items, type: :binary_id, on_delete: :restrict)

      add :kind, :string, null: false
      add :external_key, :string, null: false
      add :name, :string, null: false
      add :attributes, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:estate_inventory_items, [:snapshot_id, :kind, :external_key])
    create index(:estate_inventory_items, [:kind])

    create table(:estate_relationships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :snapshot_id, references(:estate_snapshots, type: :binary_id, on_delete: :delete_all),
        null: false

      add :from_inventory_item_id,
          references(:estate_inventory_items, type: :binary_id, on_delete: :delete_all),
          null: false

      add :to_inventory_item_id,
          references(:estate_inventory_items, type: :binary_id, on_delete: :delete_all),
          null: false

      add :evidence_item_id,
          references(:estate_evidence_items, type: :binary_id, on_delete: :restrict)

      add :kind, :string, null: false
      add :attributes, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:estate_relationships, [:snapshot_id])

    create table(:estate_findings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :assessment_run_id,
          references(:estate_assessment_runs, type: :binary_id, on_delete: :delete_all),
          null: false

      add :inventory_item_id,
          references(:estate_inventory_items, type: :binary_id, on_delete: :restrict)

      add :evidence_item_id,
          references(:estate_evidence_items, type: :binary_id, on_delete: :restrict)

      add :rule_id, :string, null: false
      add :rule_version, :string, null: false
      add :category, :string, null: false
      add :severity, :string, null: false
      add :confidence, :string, null: false
      add :summary, :string, null: false
      add :explanation, :text, null: false
      add :recommendation, :text, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:estate_findings, [:assessment_run_id])
    create index(:estate_findings, [:severity])
    create index(:estate_findings, [:status])
  end
end
