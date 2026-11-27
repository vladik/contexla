defmodule Contexla.Applications.ContentIntegrityMonitor.Package do
  @moduledoc "Content Integrity Monitor Application package."
  @behaviour Contexla.Applications.Sdk.Application
  use Contexla.Applications.Sdk.Manifest

  alias Contexla.Applications.Sdk.Instance

  @impl true
  def validate_instance_config(%{"purpose" => purpose} = config)
      when is_binary(purpose) and purpose != "",
      do: {:ok, config}

  def validate_instance_config(_config), do: {:error, {:invalid_config, "purpose is required"}}

  @impl true
  def migrate_install(repo) do
    Ecto.Adapters.SQL.query!(repo, "CREATE SCHEMA IF NOT EXISTS contexla_integrity", [])

    migrations_path =
      :content_integrity_monitor
      |> :code.priv_dir()
      |> to_string()
      |> Path.join("repo/migrations")

    Ecto.Migrator.run(repo, migrations_path, :up,
      all: true,
      prefix: "contexla_integrity",
      log: false
    )

    :ok
  rescue
    _error -> {:error, :migration_failed}
  end

  @impl true
  def execute_operation("integrity.demo_setup", %Instance{} = instance, _input) do
    Contexla.Applications.ContentIntegrityMonitor.Monitors.create_demo(instance)
  end

  def execute_operation("integrity.run", %Instance{} = instance, %{"monitor_id" => monitor_id}) do
    case Contexla.Applications.ContentIntegrityMonitor.Monitors.start_run(instance, monitor_id) do
      {:ok, run} ->
        {:ok, %{"run_id" => run.id, "status" => to_string(run.status)}, run_id: run.id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute_operation(
        "integrity.issue.acknowledge",
        %Instance{} = instance,
        %{"issue_id" => issue_id}
      ) do
    Contexla.Applications.ContentIntegrityMonitor.Monitors.transition_issue(
      instance,
      issue_id,
      :acknowledged
    )
  end

  def execute_operation(
        "integrity.issue.resolve",
        %Instance{} = instance,
        %{"issue_id" => issue_id}
      ) do
    Contexla.Applications.ContentIntegrityMonitor.Monitors.transition_issue(
      instance,
      issue_id,
      :resolved
    )
  end

  def execute_operation(_operation, _instance, _input), do: {:error, :unsupported_operation}
end
