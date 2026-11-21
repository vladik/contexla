defmodule Contexla.OperationsTest do
  use Contexla.DataCase, async: false

  alias Contexla.Accounts.Scope
  alias Contexla.Operations

  import Contexla.AccountsFixtures

  test "returns a bounded operational snapshot to an administrator" do
    admin = admin_fixture()

    {:ok, job} =
      %{support_reference: "visible-only-in-job-args"}
      |> Oban.Job.new(worker: "Contexla.TestWorker", queue: :application_runs)
      |> Oban.insert()

    assert {:ok, snapshot} = Operations.snapshot(Scope.for_user(admin))
    assert snapshot.diagnostics.status == :ok
    assert is_list(snapshot.operation_invocations)
    assert is_list(snapshot.capability_invocations)
    assert is_list(snapshot.audit_events)

    assert operational_job = Enum.find(snapshot.jobs, &(&1.id == job.id))
    refute Map.has_key?(operational_job, :args)
    refute Map.has_key?(operational_job, :errors)
  end

  test "refuses a regular user" do
    assert {:error, :forbidden} = Operations.snapshot(Scope.for_user(user_fixture()))
  end
end
