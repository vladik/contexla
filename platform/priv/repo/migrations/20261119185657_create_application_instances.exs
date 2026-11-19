defmodule Contexla.Repo.Migrations.CreateApplicationInstances do
  use Ecto.Migration

  def change do
    create table(:application_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :application_id, :string, null: false
      add :application_version, :string, null: false
      add :name, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :config, :map, null: false, default: %{}

      add :created_by_user_id,
          references(:users, type: :binary_id, on_delete: :restrict),
          null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:application_instances, [:application_id, :name])
    create index(:application_instances, [:status])
    create index(:application_instances, [:created_by_user_id])
  end
end
