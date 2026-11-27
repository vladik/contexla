defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RenameTargetProfilesTable do
  use Ecto.Migration

  def change do
    rename table(:integrity_target_profiles), to: table(:integrity_target_fact_profiles)
  end
end
