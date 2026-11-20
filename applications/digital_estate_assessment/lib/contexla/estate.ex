defmodule Contexla.Estate do
  @moduledoc """
  Digital Estate Assessment Application package.
  """

  @behaviour Contexla.ApplicationSDK.Application

  alias Contexla.ApplicationSDK.{Definition, Instance, Operation, Surface}
  alias Contexla.CapabilitySDK.Requirement

  @operations [
    %Operation{
      id: "assessment.run",
      name: "Run assessment",
      description: "Analyze approved evidence and produce draft findings.",
      requires_approval: true,
      required_capabilities: [
        %Requirement{
          capability_id: "com.contexla.dependencies.parse-composer",
          contract_version: "1"
        }
      ]
    },
    %Operation{
      id: "assessment.report",
      name: "Generate report",
      description: "Render an evidence-linked assessment report.",
      requires_approval: false
    }
  ]

  @adapter_contracts ["contexla.estate.source.v1"]

  @impl true
  def definition do
    %Definition{
      id: "com.contexla.application.digital-estate-assessment",
      name: "Digital Estate Assessment",
      icon: "hero-clipboard-document-check",
      version: "0.1.0",
      otp_application: :contexla_estate,
      entry_module: __MODULE__,
      description: "Inventory and assess a digital content estate from traceable evidence.",
      database_schema: "contexla_estate",
      config_schema: %{
        "decision" => %{type: :string, required: true},
        "scope" => %{type: :map, required: true}
      },
      operations: available_operations(),
      surfaces: [
        %Surface{
          id: :new,
          path: "new",
          module: Contexla.EstateWeb.NewLive,
          role: :new,
          label: "New assessment"
        },
        %Surface{
          id: :overview,
          path: "overview",
          module: Contexla.EstateWeb.OverviewLive,
          role: :instance,
          default: true,
          label: "Assessment overview"
        },
        %Surface{
          id: :report,
          path: "report",
          module: Contexla.EstateWeb.ReportLive,
          role: :instance,
          label: "Assessment report"
        },
        %Surface{
          id: :settings,
          path: "configuration",
          module: Contexla.EstateWeb.SettingsLive,
          role: :instance,
          kind: :settings,
          label: "Application settings"
        }
      ],
      required_adapter_contracts: required_adapter_contracts()
    }
  end

  @impl true
  def validate_instance_config(%{"decision" => decision, "scope" => scope} = config)
      when is_binary(decision) and is_map(scope) do
    if String.trim(decision) == "" do
      {:error, {:invalid_config, "decision must not be empty"}}
    else
      {:ok, config}
    end
  end

  def validate_instance_config(_config),
    do: {:error, {:invalid_config, "decision and scope are required"}}

  @impl true
  def available_operations, do: @operations

  @impl true
  def required_adapter_contracts, do: @adapter_contracts

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
    error -> {:error, {:migration_failed, Exception.message(error)}}
  end

  @impl true
  def execute_operation("assessment.run", %Instance{} = instance, %{"artifact_id" => artifact_id}) do
    Contexla.Estate.Assessments.start_run(instance, artifact_id)
  end

  def execute_operation(
        "assessment.report",
        %Instance{} = instance,
        %{"run_id" => run_id, "download" => "1"}
      ) do
    report = Contexla.Estate.Assessments.report(instance, run_id)

    {:download, Jason.encode!(report, pretty: true),
     filename: "digital-estate-assessment-#{run_id}.json", content_type: "application/json"}
  end

  def execute_operation("assessment.report", %Instance{} = instance, %{"run_id" => run_id}) do
    {:ok, Contexla.Estate.Assessments.report(instance, run_id)}
  end

  def execute_operation(_operation, _instance, _input), do: {:error, :unsupported_operation}
end
