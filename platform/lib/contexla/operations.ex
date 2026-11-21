defmodule Contexla.Operations do
  @moduledoc """
  Read-only operational visibility for an installation administrator.

  The projection intentionally excludes invocation payloads, Oban arguments,
  exception text, and artifact contents. Application-owned Run details remain
  in the owning Application.
  """

  import Ecto.Query, warn: false

  alias Contexla.Accounts.{Scope, User}
  alias Contexla.Applications.ApplicationInstance
  alias Contexla.ApplicationOperations.Invocation, as: OperationInvocation
  alias Contexla.AuditEvents.Event
  alias Contexla.Capabilities.Invocation, as: CapabilityInvocation
  alias Contexla.{CapabilityRuntime, Diagnostics, Packages, Repo}

  @recent_limit 20

  @spec snapshot(Scope.t()) :: {:ok, map()} | {:error, :forbidden}
  def snapshot(%Scope{user: %User{role: :admin}}) do
    {:ok,
     %{
       captured_at: DateTime.utc_now(:second),
       diagnostics: Diagnostics.check(),
       counts: counts(),
       packages: packages(),
       operation_invocations: operation_invocations(),
       capability_invocations: capability_invocations(),
       jobs: jobs(),
       audit_events: audit_events()
     }}
  end

  def snapshot(%Scope{}), do: {:error, :forbidden}

  @doc "Returns the explicitly allow-listed projection used in support bundles."
  @spec support_snapshot(Scope.t()) :: {:ok, map()} | {:error, :forbidden}
  def support_snapshot(%Scope{user: %User{role: :admin}} = scope) do
    with {:ok, snapshot} <- snapshot(scope) do
      {:ok,
       %{
         captured_at: iso8601(snapshot.captured_at),
         diagnostics: %{
           status: to_string(snapshot.diagnostics.status),
           checks: stringify_values(snapshot.diagnostics.checks)
         },
         counts: snapshot.counts,
         packages: support_packages(snapshot.packages),
         operation_invocations:
           Enum.map(snapshot.operation_invocations, &support_operation_invocation/1),
         capability_invocations:
           Enum.map(snapshot.capability_invocations, &support_capability_invocation/1),
         jobs: Enum.map(snapshot.jobs, &support_job/1),
         audit_events: Enum.map(snapshot.audit_events, &support_audit_event/1)
       }}
    end
  end

  def support_snapshot(%Scope{}), do: {:error, :forbidden}

  defp counts do
    %{
      instances: Repo.aggregate(ApplicationInstance, :count),
      running_operations: invocation_count(OperationInvocation, :running),
      failed_operations: invocation_count(OperationInvocation, :failed),
      running_capabilities: invocation_count(CapabilityInvocation, :running),
      failed_capabilities: invocation_count(CapabilityInvocation, [:failed, :timed_out]),
      active_jobs: job_count(["available", "executing", "retryable", "scheduled"]),
      failed_jobs: job_count(["discarded"])
    }
  end

  defp invocation_count(schema, statuses) do
    statuses = List.wrap(statuses)
    Repo.aggregate(from(invocation in schema, where: invocation.status in ^statuses), :count)
  end

  defp job_count(states) do
    Repo.aggregate(from(job in Oban.Job, where: job.state in ^states), :count)
  end

  defp packages do
    %{
      applications:
        Enum.map(safe_registry(&Packages.Registry.applications/0), fn definition ->
          %{
            id: definition.id,
            name: definition.name,
            version: definition.version,
            database_schema: definition.database_schema,
            otp_application: definition.otp_application,
            running: otp_running?(definition.otp_application)
          }
        end),
      integrations:
        Enum.map(safe_registry(&Packages.Registry.integrations/0), fn definition ->
          %{
            id: definition.id,
            name: definition.name,
            version: definition.version,
            otp_application: definition.otp_application,
            running: otp_running?(definition.otp_application)
          }
        end),
      capabilities: safe_registry(&CapabilityRuntime.Registry.capabilities/0),
      processors: safe_registry(&CapabilityRuntime.Registry.processors/0)
    }
  end

  defp safe_registry(fun) do
    fun.()
  catch
    :exit, _reason -> []
  end

  defp otp_running?(otp_application) do
    Enum.any?(Application.started_applications(), fn {application, _description, _version} ->
      application == otp_application
    end)
  end

  defp operation_invocations do
    OperationInvocation
    |> order_by([invocation], desc: invocation.started_at)
    |> limit(@recent_limit)
    |> preload([:application_instance, :invoked_by_user])
    |> Repo.all()
  end

  defp capability_invocations do
    CapabilityInvocation
    |> order_by([invocation], desc: invocation.started_at)
    |> limit(@recent_limit)
    |> preload([:application_instance, :invoked_by_user, :capability, :processor])
    |> Repo.all()
  end

  defp jobs do
    Oban.Job
    |> order_by([job], desc: job.inserted_at)
    |> limit(@recent_limit)
    |> select([job], %{
      id: job.id,
      state: job.state,
      queue: job.queue,
      worker: job.worker,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      inserted_at: job.inserted_at,
      scheduled_at: job.scheduled_at,
      attempted_at: job.attempted_at,
      completed_at: job.completed_at,
      discarded_at: job.discarded_at,
      cancelled_at: job.cancelled_at
    })
    |> Repo.all()
  end

  defp audit_events do
    Event
    |> order_by([event], desc: event.sequence)
    |> limit(@recent_limit)
    |> preload([:actor_user, :application_instance])
    |> Repo.all()
  end

  defp support_packages(packages) do
    %{
      applications:
        Enum.map(packages.applications, fn package ->
          %{
            id: package.id,
            name: package.name,
            version: package.version,
            database_schema: package.database_schema,
            otp_application: to_string(package.otp_application),
            running: package.running
          }
        end),
      integrations:
        Enum.map(packages.integrations, fn package ->
          %{
            id: package.id,
            name: package.name,
            version: package.version,
            otp_application: to_string(package.otp_application),
            running: package.running
          }
        end),
      capabilities:
        Enum.map(packages.capabilities, fn capability ->
          %{
            id: capability.id,
            contract_version: capability.contract_version,
            name: capability.name,
            owner_scope: to_string(capability.owner_scope),
            owner_key: capability.owner_key
          }
        end),
      processors:
        Enum.map(packages.processors, fn processor ->
          %{
            id: processor.id,
            version: processor.version,
            capability_id: processor.capability_id,
            capability_contract_version: processor.capability_contract_version,
            runtime: to_string(processor.runtime),
            owner_scope: to_string(processor.owner_scope),
            owner_key: processor.owner_key
          }
        end)
    }
  end

  defp support_operation_invocation(invocation) do
    %{
      id: invocation.id,
      application_instance_id: invocation.application_instance_id,
      application_id: invocation.application_id,
      application_version: invocation.application_version,
      operation_id: invocation.operation_id,
      status: to_string(invocation.status),
      run_id: invocation.run_id,
      error_code: error_code(invocation.error),
      started_at: iso8601(invocation.started_at),
      completed_at: iso8601(invocation.completed_at)
    }
  end

  defp support_capability_invocation(invocation) do
    %{
      id: invocation.id,
      application_instance_id: invocation.application_instance_id,
      capability_id: invocation.capability.key,
      capability_version: invocation.capability.contract_version,
      processor_id: invocation.processor.key,
      processor_version: invocation.processor.version,
      processor_runtime: to_string(invocation.processor.runtime),
      status: to_string(invocation.status),
      error_code: error_code(invocation.error),
      started_at: iso8601(invocation.started_at),
      completed_at: iso8601(invocation.completed_at)
    }
  end

  defp support_job(job) do
    %{
      id: job.id,
      state: job.state,
      queue: job.queue,
      worker: job.worker,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      inserted_at: iso8601(job.inserted_at),
      scheduled_at: iso8601(job.scheduled_at),
      attempted_at: iso8601(job.attempted_at),
      completed_at: iso8601(job.completed_at),
      discarded_at: iso8601(job.discarded_at),
      cancelled_at: iso8601(job.cancelled_at)
    }
  end

  defp support_audit_event(event) do
    %{
      sequence: event.sequence,
      action: event.action,
      subject_type: event.subject_type,
      application_instance_id: event.application_instance_id,
      occurred_at: iso8601(event.inserted_at)
    }
  end

  defp stringify_values(map), do: Map.new(map, fn {key, value} -> {key, to_string(value)} end)

  defp error_code(nil), do: nil
  defp error_code(%{"code" => code}) when is_binary(code), do: code
  defp error_code(%{code: code}) when is_binary(code), do: code
  defp error_code(_error), do: "operation_failed"

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  defp iso8601(%NaiveDateTime{} = datetime),
    do: datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
end
