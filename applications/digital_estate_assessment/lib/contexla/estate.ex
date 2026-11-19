defmodule Contexla.Estate do
  @moduledoc """
  Digital Estate Assessment Application package.
  """

  @behaviour Contexla.ApplicationSDK.Application

  alias Contexla.ApplicationSDK.Definition
  alias Contexla.ApplicationSDK.Operation
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
      version: "0.1.0",
      otp_application: :contexla_estate,
      entry_module: __MODULE__,
      description: "Inventory and assess a digital content estate from traceable evidence.",
      config_schema: %{
        "decision" => %{type: :string, required: true},
        "scope" => %{type: :map, required: true}
      },
      operations: available_operations(),
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
end
