defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RemoveComparisonTypeFromFacts do
  use Ecto.Migration

  def change do
    alter table(:integrity_facts, prefix: "contexla_integrity") do
      remove :comparison_type, :string
    end
  end
end
