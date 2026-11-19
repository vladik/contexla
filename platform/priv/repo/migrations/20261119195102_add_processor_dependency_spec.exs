defmodule Contexla.Repo.Migrations.AddProcessorDependencySpec do
  use Ecto.Migration

  def change do
    alter table(:processors) do
      add :dependency_spec, :map, null: false, default: %{}
    end
  end
end
