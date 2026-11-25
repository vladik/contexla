defmodule Contexla.Platform.Repo.Migrations.AddIconToApplicationInstances do
  use Ecto.Migration

  def change do
    alter table(:application_instances) do
      add :icon, :string
    end
  end
end
