defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddScopeRefFieldToSources do
  use Ecto.Migration

  def change do
    alter table(:integrity_sources) do
      add :scope_ref_field, :string
    end
  end
end
