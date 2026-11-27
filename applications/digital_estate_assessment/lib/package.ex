defmodule Contexla.Applications.DigitalEstateAssessment.Package do
  @moduledoc "Digital Estate Assessment Application package."
  @behaviour Contexla.Applications.Sdk.Application
  use Contexla.Applications.Sdk.Manifest

  alias Contexla.Applications.Sdk.Instance

  @impl true
  def validate_instance_config(%{"decision" => decision, "scope" => scope} = config)
      when is_binary(decision) and is_map(scope) do
    if String.trim(decision) == "",
      do: {:error, {:invalid_config, "decision must not be empty"}},
      else: {:ok, config}
  end

  def validate_instance_config(_config),
    do: {:error, {:invalid_config, "decision and scope are required"}}

  @impl true
  def migrate_install(repo) do
    Ecto.Adapters.SQL.query!(repo, "CREATE SCHEMA IF NOT EXISTS contexla_estate", [])

    migrations_path =
      :contexla_estate
      |> :code.priv_dir()
      |> to_string()
      |> Path.join("repo/migrations")

    Ecto.Migrator.run(repo, migrations_path, :up,
      all: true,
      prefix: "contexla_estate",
      log: false
    )

    :ok
  rescue
    _error -> {:error, :migration_failed}
  end

  @impl true
  def execute_operation("assessment.run", %Instance{} = instance, %{"artifact_id" => artifact_id}) do
    case Contexla.Applications.DigitalEstateAssessment.Assessments.start_run(instance, artifact_id) do
      {:ok, run} ->
        {:ok, %{"run_id" => run.id, "status" => to_string(run.status)}, run_id: run.id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute_operation(
        "assessment.report",
        %Instance{} = instance,
        %{"run_id" => run_id, "download" => "1"}
      ) do
    report = Contexla.Applications.DigitalEstateAssessment.Assessments.report(instance, run_id)

    {:download, Jason.encode!(report, pretty: true),
     filename: "digital-estate-assessment-#{run_id}.json",
     content_type: "application/json",
     run_id: run_id}
  end

  def execute_operation("assessment.report", %Instance{} = instance, %{"run_id" => run_id}) do
    {:ok, Contexla.Applications.DigitalEstateAssessment.Assessments.report(instance, run_id)}
  end

  def execute_operation(_operation, _instance, _input), do: {:error, :unsupported_operation}
end
