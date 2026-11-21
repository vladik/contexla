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
end
