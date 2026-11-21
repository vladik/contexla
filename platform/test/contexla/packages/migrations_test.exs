defmodule Contexla.Packages.MigrationsTest do
  use ExUnit.Case, async: true

  alias Contexla.Packages.Migrations

  defmodule NoMigrations do
  end

  defmodule SuccessfulMigrations do
    def migrate_install(Contexla.Repo), do: :ok
  end

  defmodule FailedMigrations do
    def migrate_install(Contexla.Repo), do: {:error, :migration_failed}
  end

  test "skips packages without an owned migration callback" do
    assert :ok = Migrations.run([{NoMigrations, %{id: "no-migrations"}}], Contexla.Repo)
  end

  test "runs registered Application migrations in order" do
    assert :ok =
             Migrations.run(
               [
                 {NoMigrations, %{id: "first"}},
                 {SuccessfulMigrations, %{id: "second"}}
               ],
               Contexla.Repo
             )
  end

  test "stops and identifies a failed Application migration" do
    assert {:error, {:application_migration_failed, "broken", :migration_failed}} =
             Migrations.run(
               [{FailedMigrations, %{id: "broken"}}],
               Contexla.Repo
             )
  end
end
