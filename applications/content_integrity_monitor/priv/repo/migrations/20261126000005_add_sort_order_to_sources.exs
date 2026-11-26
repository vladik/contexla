defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddSortOrderToSources do
  use Ecto.Migration

  def change do
    alter table(:integrity_sources, prefix: "contexla_integrity") do
      add :sort_order, :integer, default: 0, null: false
    end
  end
end
