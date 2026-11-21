import Ecto.Query

alias Contexla.Accounts.{Scope, User}
alias Contexla.ApplicationSDK.Instance, as: SDKInstance
alias Contexla.Applications.ApplicationInstance
alias Contexla.Estate.{AssessmentRun, Assessments}
alias Contexla.{ApplicationOperations, Applications, Repo, SourceImports}

application_id = "com.contexla.application.digital-estate-assessment"
adapter_id = "drupal.assessment.snapshot.v1"
instance_name = "Local Drupal College Estate"

baseline_path =
  System.fetch_env!("CONTEXLA_BASELINE_SNAPSHOT")
  |> Path.expand()

seeded_path =
  System.fetch_env!("CONTEXLA_SEEDED_SNAPSHOT")
  |> Path.expand()

report_path =
  System.get_env("CONTEXLA_PROOF_REPORT", "../.tmp/local-college-assessment-report.json")
  |> Path.expand()

for path <- [baseline_path, seeded_path] do
  unless File.regular?(path), do: raise("snapshot not found: #{path}")
end

user =
  User
  |> order_by([user], asc: user.inserted_at)
  |> limit(1)
  |> Repo.one() ||
    raise "No Contexla user exists. Bootstrap the initial administrator before running this proof."

scope = Scope.for_user(user)

instance =
  case Repo.get_by(ApplicationInstance, application_id: application_id, name: instance_name) do
    %ApplicationInstance{} = instance ->
      instance

    nil ->
      {:ok, instance} =
        Applications.create_instance(scope, %{
          "application_id" => application_id,
          "name" => instance_name,
          "config" => %{
            "decision" => "Assess the synthetic Drupal estate before modernization planning",
            "scope" => %{
              "cms" => "drupal",
              "environment" => "local",
              "fixture" => true
            }
          }
        })

      instance
  end

sdk_instance = %SDKInstance{
  id: instance.id,
  application_id: instance.application_id,
  application_version: instance.application_version,
  name: instance.name,
  status: instance.status,
  config: instance.config,
  actor_id: user.id
}

import_snapshot = fn path ->
  SourceImports.import(scope, instance.id, adapter_id, path,
    filename: Path.basename(path)
  )
end

wait_for_run = fn wait_for_run, run_id, attempts ->
  run = Repo.get!(AssessmentRun, run_id)

  cond do
    run.status == :succeeded ->
      run

    run.status == :failed ->
      raise "assessment run failed: #{inspect(run.error)}"

    attempts == 0 ->
      raise "assessment run did not finish: #{run_id}"

    true ->
      Process.sleep(250)
      wait_for_run.(wait_for_run, run_id, attempts - 1)
  end
end

run_snapshot = fn artifact ->
  {:ok, %{"run_id" => run_id}, invocation} =
    ApplicationOperations.invoke(
      scope,
      instance.id,
      "assessment.run",
      %{"artifact_id" => artifact.id},
      approved: true
    )

  unless invocation.run_id == run_id,
    do: raise("Operation Invocation did not link to Assessment Run")

  {wait_for_run.(wait_for_run, run_id, 120), invocation}
end

{:ok, baseline_artifact} = import_snapshot.(baseline_path)
{baseline_run, baseline_invocation} = run_snapshot.(baseline_artifact)

{:ok, seeded_artifact} = import_snapshot.(seeded_path)
{seeded_run, seeded_invocation} = run_snapshot.(seeded_artifact)

report = Assessments.report(sdk_instance, seeded_run.id)
File.mkdir_p!(Path.dirname(report_path))
File.write!(report_path, Jason.encode!(report, pretty: true))

IO.inspect(
  %{
    instance_id: instance.id,
    baseline_operation_invocation_id: baseline_invocation.id,
    baseline_run_id: baseline_run.id,
    baseline_summary: baseline_run.summary,
    seeded_operation_invocation_id: seeded_invocation.id,
    seeded_run_id: seeded_run.id,
    seeded_summary: seeded_run.summary,
    report_path: report_path
  },
  label: "Local Drupal proof"
)
