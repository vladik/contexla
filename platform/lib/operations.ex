defmodule Contexla.Platform.Operations do
  @moduledoc """
  Read-only operational visibility for an installation administrator.

  The projection intentionally excludes invocation payloads, Oban arguments,
  exception text, and artifact contents. Application-owned Run details remain
  in the owning Application.
  """

  import Ecto.Query, warn: false

  alias Contexla.Platform.Accounts.{Scope, User}
  alias Contexla.Platform.Applications.ApplicationInstance
  alias Contexla.Platform.ApplicationOperations.Invocation, as: OperationInvocation
  alias Contexla.Platform.AuditEvents.Event
  alias Contexla.Platform.Tools.Invocation, as: ToolInvocation
  alias Contexla.Platform.{Diagnostics, Packages, Repo, ToolRuntime}

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
       tool_invocations: tool_invocations(),
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
         tool_invocations: Enum.map(snapshot.tool_invocations, &support_tool_invocation/1),
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
      running_tools: invocation_count(ToolInvocation, :running),
      failed_tools: invocation_count(ToolInvocation, [:failed, :timed_out]),
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
      tools: safe_registry(&ToolRuntime.Registry.tools/0)
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

  defp tool_invocations do
    ToolInvocation
    |> order_by([invocation], desc: invocation.requested_at)
    |> limit(@recent_limit)
    |> preload([:application_instance, :invoked_by_user, :tool])
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
      tools:
        Enum.map(packages.tools, fn tool ->
          %{
            id: tool.id,
            version: tool.version,
            name: tool.name,
            runtime: to_string(tool.runtime),
            worker_profile: tool.worker_profile,
            owner_scope: to_string(tool.owner_scope),
            owner_key: tool.owner_key
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

  defp support_tool_invocation(invocation) do
    %{
      id: invocation.id,
      application_instance_id: invocation.application_instance_id,
      parent_run_id: invocation.parent_run_id,
      tool_id: invocation.tool.key,
      tool_version: invocation.tool.version,
      tool_runtime: to_string(invocation.tool.runtime),
      status: to_string(invocation.status),
      error_code: error_code(invocation.error),
      requested_at: iso8601(invocation.requested_at),
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
