defmodule Contexla.ApplicationOperations do
  @moduledoc """
  Authoritative invocation boundary for Application-declared Operations.

  UI, API, schedules, and future agents use this service so declaration,
  version, input, Capability, approval, and audit rules cannot be bypassed.
  """

  require Logger

  alias Contexla.Accounts.Scope
  alias Contexla.ApplicationOperations.Invocation
  alias Contexla.ApplicationSDK.Error
  alias Contexla.ApplicationSDK.Instance, as: SDKInstance
  alias Contexla.{Applications, Capabilities, Repo}
  alias Contexla.CapabilityRuntime.Schema
  alias Contexla.Packages.Registry

  def invoke(%Scope{} = scope, instance_id, operation_id, input, opts \\ [])
      when is_binary(operation_id) and is_map(input) do
    transport = Keyword.get(opts, :transport, :command)
    approved? = Keyword.get(opts, :approved, false)

    with {:ok, instance} <- Applications.fetch_instance(scope, instance_id),
         {:ok, {entry, definition}} <- Registry.fetch_application_entry(instance.application_id),
         operation when not is_nil(operation) <-
           Enum.find(definition.operations, &(&1.id == operation_id)),
         :ok <- allow_transport(operation, transport),
         true <- function_exported?(entry, :execute_operation, 3),
         :ok <- Schema.validate(input, operation.input_schema),
         :ok <- Capabilities.ensure_requirements(instance, operation.required_capabilities),
         :ok <- require_approval(operation, approved?),
         {:ok, invocation} <- start_invocation(scope, instance, operation, input, approved?) do
      execute(entry, operation, instance, scope, input, invocation)
    else
      nil -> {:error, :operation_not_declared}
      false -> {:error, :operation_not_executable}
      {:error, _reason} = error -> error
    end
  end

  defp allow_transport(%{kind: :read}, :read), do: :ok
  defp allow_transport(_operation, :command), do: :ok
  defp allow_transport(_operation, :read), do: {:error, :operation_requires_post}

  defp require_approval(%{requires_approval: true, id: id}, false),
    do: {:error, {:approval_required, id}}

  defp require_approval(_operation, _approved?), do: :ok

  defp start_invocation(scope, instance, operation, input, approved?) do
    now = DateTime.utc_now(:second)

    approved_by_user_id =
      if operation.requires_approval and approved?, do: scope.user.id, else: nil

    approved_at =
      if operation.requires_approval and approved?, do: now, else: nil

    attrs = %{
      application_instance_id: instance.id,
      invoked_by_user_id: scope.user.id,
      approved_by_user_id: approved_by_user_id,
      application_id: instance.application_id,
      application_version: instance.application_version,
      operation_id: operation.id,
      status: :running,
      approval_required: operation.requires_approval,
      approved_at: approved_at,
      input: Schema.audit_projection(input, operation.input_schema),
      started_at: now
    }

    %Invocation{}
    |> Invocation.start_changeset(attrs)
    |> Repo.insert()
  end

  defp execute(entry, operation, instance, scope, input, invocation) do
    context = instance_context(instance, scope.user.id)

    result =
      try do
        entry.execute_operation(operation.id, context, input)
      rescue
        error -> {:raised, error, __STACKTRACE__}
      catch
        kind, reason -> {:caught, kind, reason}
      end

    complete_result(result, invocation)
  end

  defp complete_result({:ok, result}, invocation) do
    completed = complete!(invocation, :succeeded, %{"type" => "result"}, nil, nil)
    {:ok, result, completed}
  end

  defp complete_result({:ok, result, metadata}, invocation) when is_list(metadata) do
    output = Map.merge(%{"type" => "result"}, Map.new(Keyword.get(metadata, :audit, [])))
    completed = complete!(invocation, :succeeded, output, nil, metadata[:run_id])
    {:ok, result, completed}
  end

  defp complete_result({:download, contents, options}, invocation)
       when is_binary(contents) and is_list(options) do
    output = %{
      "type" => "download",
      "filename" => options[:filename],
      "content_type" => options[:content_type]
    }

    completed = complete!(invocation, :succeeded, output, nil, options[:run_id])
    {:download, contents, Keyword.drop(options, [:run_id, :audit]), completed}
  end

  defp complete_result({:error, reason}, invocation) do
    completed = fail!(invocation, reason)
    {:error, reason, completed}
  end

  defp complete_result({:raised, error, stacktrace}, invocation) do
    {module, _function, _arity, location} = List.first(stacktrace)

    Logger.error(
      "Application Operation failed invocation_id=#{invocation.id} " <>
        "exception=#{inspect(error.__struct__)} location=#{inspect({module, location})}"
    )

    completed = fail!(invocation, :operation_exception)
    {:error, :operation_failed, completed}
  end

  defp complete_result({:caught, kind, reason}, invocation) do
    Logger.error("Application Operation failed invocation_id=#{invocation.id} kind=#{kind}")

    _ = reason

    completed = fail!(invocation, :operation_exception)
    {:error, :operation_failed, completed}
  end

  defp complete_result(_unexpected, invocation) do
    completed = fail!(invocation, :invalid_operation_result)
    {:error, :invalid_operation_result, completed}
  end

  defp fail!(invocation, reason) do
    complete!(invocation, :failed, nil, Error.map(reason), nil)
  end

  defp complete!(invocation, status, output, error, run_id) do
    invocation
    |> Invocation.complete_changeset(%{
      status: status,
      output: output,
      error: error,
      run_id: run_id,
      completed_at: DateTime.utc_now(:second)
    })
    |> Repo.update!()
  end

  defp instance_context(instance, actor_id) do
    %SDKInstance{
      id: instance.id,
      application_id: instance.application_id,
      application_version: instance.application_version,
      name: instance.name,
      description: instance.description,
      status: instance.status,
      config: instance.config,
      actor_id: actor_id
    }
  end
end
