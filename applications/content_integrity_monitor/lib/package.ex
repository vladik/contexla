defmodule Contexla.Applications.ContentIntegrityMonitor.Package do
  @moduledoc "Content Integrity Monitor Application package."
  @behaviour Contexla.Applications.Sdk.Application

  alias Contexla.Applications.Sdk.{Definition, Instance, Operation, Surface}
  alias Contexla.Tools.Sdk.Requirement

  @extract_json %Requirement{tool_id: "com.contexla.extract.json-values", version: "1.0.0"}
  @extract_html %Requirement{tool_id: "com.contexla.extract.html-values", version: "1.0.0"}
  @issue_input_schema %{
    "type" => "object",
    "required" => ["issue_id"],
    "additionalProperties" => false,
    "properties" => %{"issue_id" => %{"type" => "string"}}
  }

  @operations [
    %Operation{
      id: "integrity.demo_setup",
      name: "Create demonstration monitor",
      description: "Create the deterministic program-content integrity demonstration.",
      requires_approval: true
    },
    %Operation{
      id: "integrity.run",
      name: "Run monitor",
      description: "Acquire configured sources and evaluate content integrity.",
      input_schema: %{
        "type" => "object",
        "required" => ["monitor_id"],
        "additionalProperties" => false,
        "properties" => %{"monitor_id" => %{"type" => "string"}}
      },
      required_tools: [@extract_json, @extract_html]
    },
    %Operation{
      id: "integrity.issue.acknowledge",
      name: "Acknowledge issue",
      description: "Mark an open integrity Issue as acknowledged.",
      input_schema: @issue_input_schema
    },
    %Operation{
      id: "integrity.issue.resolve",
      name: "Resolve issue",
      description: "Mark an open or acknowledged integrity Issue as resolved.",
      input_schema: @issue_input_schema
    }
  ]

  @impl true
  def definition do
    %Definition{
      id: "com.contexla.application.content-integrity-monitor",
      name: "Content Integrity Monitor",
      icon: "hero-shield-check",
      version: "0.1.0",
      otp_application: :content_integrity_monitor,
      entry_module: __MODULE__,
      description:
        "Detect missing, delayed, unavailable, or inconsistent facts across digital representations.",
      database_schema: "contexla_integrity",
      config_schema: %{
        "purpose" => %{type: :string, required: true}
      },
      operations: available_operations(),
      surfaces: [
        %Surface{
          id: :new,
          path: "new",
          module: Contexla.Applications.ContentIntegrityMonitor.Web.NewLive,
          role: :new,
          label: "New Instance"
        },
        %Surface{
          id: :overview,
          path: "overview",
          module: Contexla.Applications.ContentIntegrityMonitor.Web.OverviewLive,
          role: :instance,
          default: true,
          label: "Overview"
        },
        %Surface{
          id: :collection,
          path: "monitors",
          module: Contexla.Applications.ContentIntegrityMonitor.Web.CollectionLive,
          role: :instance,
          label: "Monitors"
        },
        %Surface{
          id: :settings,
          path: "configuration",
          module: Contexla.Applications.ContentIntegrityMonitor.Web.SettingsLive,
          role: :instance,
          kind: :settings,
          label: "Application settings"
        }
      ] ++ dev_surfaces(),
      required_adapter_contracts: required_adapter_contracts()
    }
  end

  @impl true
  def validate_instance_config(%{"purpose" => purpose} = config)
      when is_binary(purpose) and purpose != "",
      do: {:ok, config}

  def validate_instance_config(_config), do: {:error, {:invalid_config, "purpose is required"}}

  @impl true
  def available_operations, do: @operations

  @impl true
  def required_adapter_contracts, do: []

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

  if Mix.env() == :dev do
    defp dev_surfaces do
      [
        %Surface{
          id: :dev,
          path: "dev",
          module: Contexla.Applications.ContentIntegrityMonitor.Web.DevLive,
          role: :instance,
          label: "Developer"
        }
      ]
    end
  else
    defp dev_surfaces, do: []
  end
end
