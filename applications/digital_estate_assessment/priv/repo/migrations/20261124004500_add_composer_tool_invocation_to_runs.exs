defmodule Contexla.Applications.DigitalEstateAssessment.Repo.Migrations.AddComposerToolInvocationToRuns do
  use Ecto.Migration

  def change do
    alter table(:estate_assessment_runs) do
      add :composer_tool_invocation_id, :binary_id
    end

    create index(:estate_assessment_runs, [:composer_tool_invocation_id])
  end
end
