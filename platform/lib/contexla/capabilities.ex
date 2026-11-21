defmodule Contexla.Capabilities do
  @moduledoc """
  Public, authenticated API for invoking Capability contracts through bound
  Processor implementations.
  """

  alias Contexla.Accounts.{Scope, User}
  alias Contexla.ApplicationSDK.Error
  alias Contexla.Applications.ApplicationInstance
  alias Contexla.Capabilities.{Catalog, Contract, Invocation, Resolver}
  alias Contexla.CapabilityRuntime.{Registry, Schema}
  alias Contexla.CapabilitySDK.Requirement
  alias Contexla.CapabilityRuntime.Runners.Native
  alias Contexla.Repo

  def invoke(
        %Scope{user: %User{} = user},
        %ApplicationInstance{} = instance,
        capability_key,
        contract_version,
        input
      )
      when is_map(input) do
    with :ok <- Catalog.sync_bundled(),
         %Contract{} = contract <-
           Repo.get_by(Contract,
             key: capability_key,
             contract_version: contract_version,
             status: :active
           ),
         :ok <- Schema.validate(input, contract.input_schema),
         {:ok, binding, processor} <- Resolver.resolve(contract, instance),
         :ok <- Schema.validate(binding.config, processor.config_schema),
         {:ok, definition} <- Registry.fetch_processor(processor.key, processor.version),
         {:ok, invocation} <-
           start_invocation(user, instance, contract, binding, processor, input) do
      execute(invocation, contract, binding, processor, definition, input)
    else
      nil -> {:error, :capability_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Validates that required Capability contracts have executable bindings for an Instance."
  def ensure_requirements(%ApplicationInstance{} = instance, requirements)
      when is_list(requirements) do
    with :ok <- Catalog.sync_bundled() do
      Enum.reduce_while(requirements, :ok, fn %Requirement{} = requirement, :ok ->
        case ensure_requirement(instance, requirement) do
          :ok ->
            {:cont, :ok}

          {:error, _reason} when requirement.optional ->
            {:cont, :ok}

          {:error, reason} ->
            {:halt,
             {:error,
              {:required_capability_unavailable, requirement.capability_id,
               requirement.contract_version, reason}}}
        end
      end)
    end
  end

  defp ensure_requirement(instance, requirement) do
    case Repo.get_by(Contract,
           key: requirement.capability_id,
           contract_version: requirement.contract_version,
           status: :active
         ) do
      nil -> {:error, :capability_not_found}
      contract -> requirement_binding(contract, instance)
    end
  end

  defp requirement_binding(contract, instance) do
    with {:ok, _binding, processor} <- Resolver.resolve(contract, instance),
         {:ok, _definition} <- Registry.fetch_processor(processor.key, processor.version) do
      :ok
    end
  end

  defp execute(invocation, contract, binding, processor, definition, input) do
    context = %{
      invocation_id: invocation.id,
      config: binding.config,
      granted_permissions: binding.granted_permissions
    }

    result =
      case definition.runtime do
        :native -> Native.run(definition.entrypoint, input, context, processor.timeout_ms)
        runtime -> {:error, {:unsupported_processor_runtime, runtime}}
      end

    case result do
      {:ok, output} ->
        case Schema.validate(output, contract.output_schema) do
          :ok -> succeed(invocation, contract, output)
          {:error, error} -> fail(invocation, {:invalid_processor_output, error})
        end

      {:error, :timeout} ->
        finish_error(invocation, :timed_out, :timeout)

      {:error, reason} ->
        fail(invocation, reason)
    end
  end

  defp start_invocation(user, instance, contract, binding, processor, input) do
    %Invocation{}
    |> Invocation.start_changeset(%{
      capability_id: contract.id,
      processor_id: processor.id,
      binding_id: binding.id,
      application_instance_id: instance.id,
      invoked_by_user_id: user.id,
      status: :running,
      input: Schema.audit_projection(input, contract.input_schema),
      started_at: DateTime.utc_now(:second)
    })
    |> Repo.insert()
  end

  defp complete(invocation, status, output, error) do
    invocation
    |> Invocation.complete_changeset(%{
      status: status,
      output: output,
      error: error,
      completed_at: DateTime.utc_now(:second)
    })
    |> Repo.update()
    |> case do
      {:ok, completed} when status == :succeeded -> {:ok, output, completed}
      {:ok, completed} -> {:error, completed.error, completed}
      {:error, changeset} -> {:error, {:invocation_update_failed, changeset}}
    end
  end

  defp succeed(invocation, contract, output) do
    audit_output = Schema.audit_projection(output, contract.output_schema)

    case complete(invocation, :succeeded, audit_output, nil) do
      {:ok, _audit_output, completed} -> {:ok, output, completed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fail(invocation, reason), do: finish_error(invocation, :failed, reason)

  defp finish_error(invocation, status, reason) do
    case complete(invocation, status, nil, Error.map(reason, "capability_failed")) do
      {:error, _stored_error, completed} -> {:error, reason, completed}
      {:error, persistence_error} -> {:error, persistence_error}
    end
  end
end
