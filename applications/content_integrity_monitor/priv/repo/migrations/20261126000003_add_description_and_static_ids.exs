defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddDescriptionAndStaticIds do
  use Ecto.Migration

  def up do
    alter table(:integrity_monitors, prefix: "contexla_integrity") do
      add :description, :text
    end

    alter table(:integrity_sources, prefix: "contexla_integrity") do
      add :static_ids, :text
    end
  end

  def down do
    alter table(:integrity_sources, prefix: "contexla_integrity") do
      remove :static_ids
    end

    alter table(:integrity_monitors, prefix: "contexla_integrity") do
      remove :description
    end
  end
end
