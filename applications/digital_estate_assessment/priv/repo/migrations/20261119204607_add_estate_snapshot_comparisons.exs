defmodule Contexla.Estate.Migrations.AddEstateSnapshotComparisons do
  use Ecto.Migration

  def change do
    create table(:estate_snapshot_comparisons, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :previous_snapshot_id,
          references(:estate_snapshots, type: :binary_id, on_delete: :delete_all),
          null: false

      add :current_snapshot_id,
          references(:estate_snapshots, type: :binary_id, on_delete: :delete_all),
          null: false

      add :summary, :map, null: false, default: %{}
      add :changes, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:estate_snapshot_comparisons, [:current_snapshot_id])
    create index(:estate_snapshot_comparisons, [:previous_snapshot_id])
  end
end
