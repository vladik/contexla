defmodule Contexla.Estate.Migrations.AddEstateFindingReview do
  use Ecto.Migration

  def change do
    alter table(:estate_findings) do
      add :origin, :string, null: false, default: "deterministic"
      add :created_by_user_id,
          references(:users, type: :binary_id, on_delete: :restrict, prefix: "public")
      modify :rule_id, :string, null: true
      modify :rule_version, :string, null: true
    end

    create index(:estate_findings, [:origin])
    create index(:estate_findings, [:created_by_user_id])

    create table(:estate_review_decisions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :finding_id, references(:estate_findings, type: :binary_id, on_delete: :delete_all),
        null: false

      add :reviewed_by_user_id,
          references(:users, type: :binary_id, on_delete: :restrict, prefix: "public"),
        null: false

      add :from_status, :string, null: false
      add :to_status, :string, null: false
      add :rationale, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:estate_review_decisions, [:finding_id])
    create index(:estate_review_decisions, [:reviewed_by_user_id])
  end
end
