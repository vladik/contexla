defmodule Contexla.Platform.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :adapter_key, :string, null: false
      add :base_url, :string, null: false
      add :settings, :map, null: false, default: %{}
      add :credentials, :text

      timestamps(type: :utc_datetime)
    end

    create index(:connections, [:adapter_key])
    create unique_index(:connections, [:name])
  end
end
