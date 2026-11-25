defmodule Contexla.Platform.Repo.Migrations.AddDescriptionToApplicationInstances do
  use Ecto.Migration

  def change do
    alter table(:application_instances) do
      add :description, :text
    end
  end
end
