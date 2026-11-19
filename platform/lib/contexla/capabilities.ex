defmodule Contexla.Capabilities do
  @moduledoc """
  Public, authenticated API for invoking Capability contracts through bound
  Processor implementations.
  """

  alias Contexla.Accounts.{Scope, User}
  alias Contexla.Applications.ApplicationInstance
  alias Contexla.Capabilities.{Catalog, Contract, Invocation, Resolver}
  alias Contexla.CapabilityRuntime.{Registry, Schema}
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
          :ok -> complete(invocation, :succeeded, output, nil)
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
      input: input,
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

  defp fail(invocation, reason), do: finish_error(invocation, :failed, reason)

  defp finish_error(invocation, status, reason) do
    error = %{"reason" => inspect(reason)}
    complete(invocation, status, nil, error)
  end
end
