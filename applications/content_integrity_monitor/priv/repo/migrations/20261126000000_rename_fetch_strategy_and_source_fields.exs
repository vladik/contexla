defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RenameFetchStrategyAndSourceFields do
  use Ecto.Migration

  def up do
    execute "UPDATE contexla_integrity.integrity_sources SET fetch_strategy = 'fetch_entity' WHERE fetch_strategy = 'per_item'"
    execute "UPDATE contexla_integrity.integrity_sources SET fetch_strategy = 'fetch_all_entities' WHERE fetch_strategy = 'bulk'"
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'scope' WHERE role = 'scope_master'"

    rename table(:integrity_sources, prefix: "contexla_integrity"), :scope_key_path, to: :array_path

    alter table(:integrity_sources, prefix: "contexla_integrity") do
      add :id_field, :string, default: "id"
    end

    execute "UPDATE contexla_integrity.integrity_sources SET url = item_url_template WHERE item_url_template IS NOT NULL AND url IS NULL"

    alter table(:integrity_sources, prefix: "contexla_integrity") do
      remove :item_url_template
    end
  end

  def down do
    alter table(:integrity_sources, prefix: "contexla_integrity") do
      add :item_url_template, :string
      remove :id_field
    end

    rename table(:integrity_sources, prefix: "contexla_integrity"), :array_path, to: :scope_key_path

    execute "UPDATE contexla_integrity.integrity_sources SET role = 'scope_master' WHERE role = 'scope'"
    execute "UPDATE contexla_integrity.integrity_sources SET fetch_strategy = 'per_item' WHERE fetch_strategy = 'fetch_entity'"
    execute "UPDATE contexla_integrity.integrity_sources SET fetch_strategy = 'bulk' WHERE fetch_strategy = 'fetch_all_entities'"
  end
end
