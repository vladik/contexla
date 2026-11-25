defmodule Contexla.Platform.Release do
  @moduledoc "Release-safe installation and diagnostic commands invoked through `bin/contexla eval`."

  @app :contexla

  @spec migrate_all() :: :ok
  def migrate_all do
    load_app!()
    prepare_artifact_storage!()
    migrate_platform!()
    start_for_package_migrations!()

    case Contexla.Platform.Packages.Migrations.run_all() do
      :ok -> :ok
      {:error, reason} -> raise "registered package migration failed: #{error_code(reason)}"
    end
  end

  @spec bootstrap_admin() :: :ok
  def bootstrap_admin do
    start_app!()

    attrs = %{
      email: fetch_env!("CONTEXLA_ADMIN_EMAIL"),
      password: fetch_env!("CONTEXLA_ADMIN_PASSWORD")
    }

    case Contexla.Platform.Accounts.bootstrap_admin(attrs) do
      {:ok, _user} ->
        :ok

      {:error, :already_bootstrapped} ->
        raise "administrator bootstrap refused: already_bootstrapped"

      {:error, _changeset} ->
        raise "administrator bootstrap failed: invalid_credentials"
    end
  end

  @spec diagnostics() :: :ok
  def diagnostics do
    start_app!()
    result = Contexla.Platform.Diagnostics.check()
    IO.puts(Jason.encode!(json_result(result)))

    if result.status == :ok do
      :ok
    else
      raise "diagnostics failed"
    end
  end

  defp migrate_platform! do
    for repo <- Application.fetch_env!(@app, :ecto_repos) do
      case Ecto.Migrator.with_repo(repo, fn repo ->
             Ecto.Migrator.run(repo, :up, all: true)
           end) do
        {:ok, _versions, _apps} -> :ok
        {:error, reason} -> raise "platform migration failed: #{error_code(reason)}"
      end
    end

    :ok
  end

  defp start_for_package_migrations! do
    Application.put_env(@app, :start_registered_packages, false)
    start_app!()
  end

  defp start_app! do
    case Application.ensure_all_started(@app) do
      {:ok, _applications} -> :ok
      {:error, reason} -> raise "Contexla startup failed: #{error_code(reason)}"
    end
  end

  defp load_app! do
    case Application.load(@app) do
      :ok -> :ok
      {:error, {:already_loaded, @app}} -> :ok
      {:error, reason} -> raise "Contexla load failed: #{error_code(reason)}"
    end
  end

  defp prepare_artifact_storage! do
    @app
    |> Application.fetch_env!(:artifact_storage_path)
    |> File.mkdir_p!()
  end

  defp fetch_env!(name) do
    case System.fetch_env(name) do
      {:ok, value} when value != "" -> value
      _missing -> raise "#{name} is required"
    end
  end

  defp error_code(reason),
    do: Contexla.Applications.Sdk.Error.code(reason, "release_command_failed")

  defp json_result(result) do
    %{
      "status" => Atom.to_string(result.status),
      "checks" =>
        Map.new(result.checks, fn {name, status} ->
          {Atom.to_string(name), Atom.to_string(status)}
        end)
    }
  end
end
