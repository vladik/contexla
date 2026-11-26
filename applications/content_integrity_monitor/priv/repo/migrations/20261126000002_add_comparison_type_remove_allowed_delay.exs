defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddComparisonTypeRemoveAllowedDelay do
  use Ecto.Migration

  def up do
    alter table(:integrity_facts, prefix: "contexla_integrity") do
      add :comparison_type, :string, default: "text", null: false
    end

    alter table(:integrity_sources, prefix: "contexla_integrity") do
      remove :allowed_delay_seconds
    end

    execute "UPDATE contexla_integrity.integrity_monitors SET status = 'disabled' WHERE status = 'paused'"
  end

  def down do
    alter table(:integrity_facts, prefix: "contexla_integrity") do
      remove :comparison_type
    end

    alter table(:integrity_sources, prefix: "contexla_integrity") do
      add :allowed_delay_seconds, :integer, default: 0
    end

    execute "UPDATE contexla_integrity.integrity_monitors SET status = 'paused' WHERE status = 'disabled'"
  end
end
