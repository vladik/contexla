defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.AddConnectionToSourcesRemoveFormat do
  use Ecto.Migration

  def change do
    alter table(:integrity_sources, prefix: "contexla_integrity") do
      add :connection_id, :binary_id
      remove :format, :string
    end
  end
end
