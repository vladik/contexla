defmodule Contexla.OperationsFailureDrillTest do
  @moduledoc """
  Repeatable support drill for the shared operational boundaries.

  Run with:

      mix test test/contexla/operations_failure_drill_test.exs
  """

  use Contexla.DataCase, async: false

  alias Contexla.{ApplicationOperations, Applications, AuditEvents, Capabilities, Repo}
  alias Contexla.Accounts.Scope
  alias Contexla.AuditEvents.Event
  alias Contexla.SupportBundles

  import Contexla.AccountsFixtures

  @job_secret "JOB_ARGUMENT_SECRET_MUST_NOT_LEAK"
  @error_secret "EXCEPTION_DETAIL_SECRET_MUST_NOT_LEAK"
  @audit_secret "AUDIT_METADATA_SECRET_MUST_NOT_LEAK"
  @content_secret "PRIVATE_COMPOSER_CONTENT_MUST_NOT_LEAK"

  test "failed execution is correlatable while the bundle excludes sensitive records" do
    admin = admin_fixture()
    scope = Scope.for_user(admin)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Operations Drill Instance",
        "config" => %{}
      })

    assert {:error, :expected_failure, operation_invocation} =
             ApplicationOperations.invoke(scope, instance.id, "test.failure", %{})

    assert {:ok, _output, capability_invocation} =
             Capabilities.invoke(
               scope,
               instance,
               "com.contexla.dependencies.parse-composer",
               "2",
               %{
                 "composer_json" => %{
                   "require" => %{"private/package" => @content_secret}
                 },
                 "composer_lock" => %{
                   "packages" => [
                     %{
                       "name" => "private/package",
                       "version" => @content_secret,
                       "type" => "library"
                     }
                   ]
                 }
               }
             )

    capability_invocation =
      capability_invocation
      |> Ecto.Changeset.change(
        status: :failed,
        output: %{"private_result" => @content_secret},
        error: %{"code" => "drill_capability_failure", "detail" => @error_secret}
      )
      |> Repo.update!()

    job = insert_discarded_job()

    assert {:ok, _event} =
             AuditEvents.record(scope, %{
               action: "operations.drill.failure",
               subject_type: "operations_drill",
               subject_id: @audit_secret,
               application_instance_id: instance.id,
               metadata: %{"unsafe_detail" => @audit_secret}
             })

    assert {:ok, bundle} = SupportBundles.generate(scope)
    files = unzip(bundle.contents)
    combined = files |> Map.values() |> IO.iodata_to_binary()

    assert combined =~ operation_invocation.id
    assert combined =~ "expected_failure"
    assert combined =~ capability_invocation.id
    assert combined =~ "drill_capability_failure"
    assert combined =~ Integer.to_string(job.id)
    assert combined =~ "discarded"
    assert combined =~ "operations.drill.failure"
    assert Repo.exists?(from event in Event, where: event.action == "support_bundle.generated")

    refute combined =~ admin.email
    refute combined =~ @job_secret
    refute combined =~ @error_secret
    refute combined =~ @audit_secret
    refute combined =~ @content_secret

    assert %{
             "schema_version" => "1",
             "files" => [_health, _runtime, _activity],
             "exclusions" => exclusions
           } = Jason.decode!(files["manifest.json"])

    assert "credentials" in exclusions
    assert "raw_logs" in exclusions
  end

  test "a regular user cannot generate a bundle" do
    assert {:error, :forbidden} =
             SupportBundles.generate(Scope.for_user(user_fixture()))
  end

  defp insert_discarded_job do
    now = DateTime.utc_now()

    %{"unsafe_argument" => @job_secret}
    |> Oban.Job.new(worker: "Contexla.OperationsDrillWorker", queue: :application_runs)
    |> Ecto.Changeset.change(
      state: "discarded",
      attempt: 1,
      discarded_at: now,
      errors: [%{"at" => DateTime.to_iso8601(now), "attempt" => 1, "error" => @error_secret}]
    )
    |> Repo.insert!()
  end

  defp unzip(contents) do
    assert {:ok, entries} = :zip.extract(contents, [:memory])
    Map.new(entries, fn {name, value} -> {List.to_string(name), value} end)
  end
end
