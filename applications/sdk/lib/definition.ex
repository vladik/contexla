defmodule Contexla.Applications.Sdk.Definition do
  @moduledoc """
  Declarative identity and contract for a trusted Application package.
  Derived at runtime from the application's contexla-application.json manifest.
  """

  alias Contexla.Applications.Sdk.{Operation, Queue, Surface}

  @enforce_keys [:id, :name, :icon, :version, :otp_application, :entry_module]
  defstruct [
    :id,
    :name,
    :icon,
    :version,
    :otp_application,
    :entry_module,
    :database_schema,
    description: "",
    config_schema: %{},
    queues: [],
    operations: [],
    surfaces: [],
    required_adapter_contracts: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          icon: String.t(),
          version: String.t(),
          otp_application: atom(),
          entry_module: module(),
          database_schema: String.t() | nil,
          description: String.t(),
          config_schema: map(),
          queues: [Queue.t()],
          operations: [Operation.t()],
          surfaces: [Surface.t()],
          required_adapter_contracts: [String.t()]
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = definition) do
    validators = [
      {:id, definition.id, &non_empty_string?/1},
      {:name, definition.name, &non_empty_string?/1},
      {:icon, definition.icon, &icon?/1},
      {:version, definition.version, &non_empty_string?/1},
      {:otp_application, definition.otp_application, &is_atom/1},
      {:entry_module, definition.entry_module, &is_atom/1},
      {:database_schema, definition.database_schema, &optional_identifier?/1},
      {:description, definition.description, &is_binary/1},
      {:config_schema, definition.config_schema, &is_map/1},
      {:queues, definition.queues, &queues?/1},
      {:operations, definition.operations, &operations?/1},
      {:surfaces, definition.surfaces, &surfaces?/1},
      {:required_adapter_contracts, definition.required_adapter_contracts, &string_list?/1}
    ]

    with nil <- Enum.find(validators, fn {_field, value, validator} -> not validator.(value) end),
         :ok <- validate_surface_contract(definition.surfaces),
         :ok <- validate_operation_contract(definition.operations) do
      :ok
    else
      {field, value, _validator} -> {:error, {:invalid_field, field, value}}
      {:error, _reason} = error -> error
    end
  end

  defp validate_operation_contract(operations) do
    ids = Enum.map(operations, & &1.id)
    if Enum.uniq(ids) == ids, do: :ok, else: {:error, :duplicate_operation_id}
  end

  defp validate_surface_contract(surfaces) do
    ids = Enum.map(surfaces, & &1.id)
    paths = Enum.map(surfaces, & &1.path)
    new_surfaces = Enum.filter(surfaces, &(&1.role == :new))
    default_surfaces = Enum.filter(surfaces, &(&1.role == :instance and &1.default))
    settings_surfaces = Enum.filter(surfaces, &(&1.role == :instance and &1.kind == :settings))

    cond do
      length(Enum.uniq(ids)) != length(ids) -> {:error, :duplicate_surface_id}
      length(Enum.uniq(paths)) != length(paths) -> {:error, :duplicate_surface_path}
      length(new_surfaces) != 1 -> {:error, :one_new_surface_required}
      length(default_surfaces) != 1 -> {:error, :one_default_instance_surface_required}
      length(settings_surfaces) != 1 -> {:error, :one_instance_settings_surface_required}
      true -> :ok
    end
  end

  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp icon?(value),
    do: non_empty_string?(value) and value =~ ~r/^hero-[a-z0-9-]+$/

  defp queues?(value),
    do:
      is_list(value) and
        Enum.all?(value, &(match?(%Queue{}, &1) and Queue.validate(&1) == :ok))

  defp operations?(value),
    do:
      is_list(value) and
        Enum.all?(value, &(match?(%Operation{}, &1) and Operation.validate(&1) == :ok))

  defp string_list?(value), do: is_list(value) and Enum.all?(value, &non_empty_string?/1)

  defp surfaces?(value),
    do:
      is_list(value) and
        Enum.all?(value, &(match?(%Surface{}, &1) and Surface.validate(&1) == :ok))

  defp optional_identifier?(nil), do: true

  defp optional_identifier?(value),
    do: non_empty_string?(value) and value =~ ~r/^[a-z][a-z0-9_]*$/
end
