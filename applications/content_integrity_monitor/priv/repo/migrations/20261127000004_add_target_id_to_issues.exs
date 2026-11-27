defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddTargetIdToIssues do
  use Ecto.Migration

  def change do
    alter table(:integrity_issues) do
      add :target_id,
          references(:integrity_sources, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:integrity_issues, [:target_id], where: "target_id IS NOT NULL")
  end
end
