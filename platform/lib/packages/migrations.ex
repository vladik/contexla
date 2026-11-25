defmodule Contexla.Platform.Packages.Migrations do
  @moduledoc """
  Explicitly runs migrations owned by registered trusted Applications.

  Package discovery never mutates the database. Curated installation and
  upgrade processes call this service after platform migrations and before the
  server accepts traffic.
  """

  alias Contexla.Platform.Packages.Registry
  alias Contexla.Platform.Repo

  @spec run_all() :: :ok | {:error, term()}
  def run_all do
    run(Registry.application_entries(), Repo)
  end

  @doc false
  def run(entries, repo) when is_list(entries) and is_atom(repo) do
    entries
    |> Enum.reduce_while(:ok, fn {module, definition}, :ok ->
      case migrate(module, repo) do
        :ok ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {:application_migration_failed, definition.id, reason}}}
      end
    end)
  end

  defp migrate(module, repo) do
    if function_exported?(module, :migrate_install, 1) do
      module.migrate_install(repo)
    else
      :ok
    end
  end
end
