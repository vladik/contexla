defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.InitializeSourceSortOrders do
  use Ecto.Migration

  def up do
    execute """
    UPDATE contexla_integrity.integrity_sources s
    SET sort_order = sub.rn - 1
    FROM (
      SELECT id,
             ROW_NUMBER() OVER (PARTITION BY monitor_id, role ORDER BY inserted_at) AS rn
      FROM contexla_integrity.integrity_sources
    ) sub
    WHERE s.id = sub.id
    """
  end

  def down do
    execute "UPDATE contexla_integrity.integrity_sources SET sort_order = 0"
  end
end
