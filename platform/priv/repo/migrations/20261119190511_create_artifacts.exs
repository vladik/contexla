defmodule Contexla.Repo.Migrations.CreateArtifacts do
  use Ecto.Migration

  def change do
    create table(:artifacts, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :application_instance_id,
          references(:application_instances, type: :binary_id, on_delete: :restrict),
          null: false

      add :created_by_user_id,
          references(:users, type: :binary_id, on_delete: :restrict),
          null: false

      add :kind, :string, null: false
      add :source_type, :string, null: false
      add :filename, :string, null: false
      add :media_type, :string, null: false
      add :sha256, :string, null: false
      add :byte_size, :bigint, null: false
      add :storage_key, :string, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:artifacts, [:application_instance_id, :kind, :sha256])
    create index(:artifacts, [:application_instance_id])
    create index(:artifacts, [:created_by_user_id])
    create index(:artifacts, [:sha256])
  end
end
