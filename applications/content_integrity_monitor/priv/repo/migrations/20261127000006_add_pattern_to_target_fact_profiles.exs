defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddPatternToTargetFactProfiles do
  use Ecto.Migration

  def change do
    alter table(:integrity_target_fact_profiles, prefix: "contexla_integrity") do
      add :pattern, :string
    end
  end
end
