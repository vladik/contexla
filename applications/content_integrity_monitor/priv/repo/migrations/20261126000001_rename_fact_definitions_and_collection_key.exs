defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RenameFactDefinitionsAndCollectionKey do
  use Ecto.Migration

  def up do
    rename table(:integrity_fact_definitions, prefix: "contexla_integrity"),
           to: table(:integrity_facts, prefix: "contexla_integrity")

    rename table(:integrity_monitors, prefix: "contexla_integrity"),
           :collection_key,
           to: :entity_type

    execute "UPDATE contexla_integrity.integrity_sources SET role = 'primary' WHERE role = 'authority'"
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'secondary' WHERE role = 'representation'"

    rename table(:integrity_observations, prefix: "contexla_integrity"),
           :fact_definition_id,
           to: :fact_id

    rename table(:integrity_issues, prefix: "contexla_integrity"),
           :fact_definition_id,
           to: :fact_id
  end

  def down do
    rename table(:integrity_facts, prefix: "contexla_integrity"),
           to: table(:integrity_fact_definitions, prefix: "contexla_integrity")

    rename table(:integrity_monitors, prefix: "contexla_integrity"),
           :entity_type,
           to: :collection_key

    execute "UPDATE contexla_integrity.integrity_sources SET role = 'authority' WHERE role = 'primary'"
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'representation' WHERE role = 'secondary'"

    rename table(:integrity_observations, prefix: "contexla_integrity"),
           :fact_id,
           to: :fact_definition_id

    rename table(:integrity_issues, prefix: "contexla_integrity"),
           :fact_id,
           to: :fact_definition_id
  end
end
