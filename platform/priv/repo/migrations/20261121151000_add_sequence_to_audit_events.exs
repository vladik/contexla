defmodule Contexla.Repo.Migrations.AddSequenceToAuditEvents do
  use Ecto.Migration

  def change do
    alter table(:audit_events) do
      add :sequence, :bigserial, null: false
    end

    create unique_index(:audit_events, [:sequence])
  end
end
