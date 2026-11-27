defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RenameRefFields do
  use Ecto.Migration

  def change do
    rename table(:integrity_sources), :id_field, to: :ref_field
    rename table(:integrity_sources), :static_ids, to: :static_refs

    rename table(:integrity_observations), :entity_id, to: :ref_id
    rename table(:integrity_issues), :entity_id, to: :ref_id
    rename table(:integrity_evidence), :entity_id, to: :ref_id
    rename table(:integrity_source_checks), :entity_id, to: :ref_id
  end
end
