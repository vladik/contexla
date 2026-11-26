defmodule Contexla.Applications.ContentIntegrityMonitor.Repo.Migrations.RenameSourceRoles do
  use Ecto.Migration

  def up do
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'source' WHERE role = 'primary'"
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'target' WHERE role = 'secondary'"
  end

  def down do
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'primary' WHERE role = 'source'"
    execute "UPDATE contexla_integrity.integrity_sources SET role = 'secondary' WHERE role = 'target'"
  end
end
