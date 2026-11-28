defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RemoveToolInvocationIds do
  use Ecto.Migration

  def change do
    alter table(:integrity_source_checks, prefix: "contexla_integrity") do
      remove :tool_invocation_id, :binary_id
    end

    alter table(:integrity_evidence, prefix: "contexla_integrity") do
      remove :tool_invocation_id, :binary_id
    end
  end
end
