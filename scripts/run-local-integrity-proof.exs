import Ecto.Query
require Logger

Logger.configure(level: :warning)

alias Contexla.Applications.Sdk.Instance, as: SDKInstance
alias Contexla.Applications.ContentIntegrityMonitor.{Monitors, Run}
alias Contexla.Platform.Accounts.{Scope, User}
alias Contexla.Platform.Applications.ApplicationInstance
alias Contexla.Platform.{ApplicationOperations, Applications, Repo}

application_id = "com.contexla.application.content-integrity-monitor"
instance_name =
  System.get_env("CONTEXLA_INTEGRITY_INSTANCE_NAME", "Local Content Integrity Proof")

base_url = System.get_env("CONTEXLA_INTEGRITY_DEMO_URL", "http://localhost:4205")

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
            "purpose" => "Prove evidence-backed consistency monitoring across content delivery",
            "demo_base_url" => base_url
          }
        })

      instance
  end

sdk_instance = %SDKInstance{
  id: instance.id,
  application_id: instance.application_id,
  application_version: instance.application_version,
  name: instance.name,
  description: instance.description,
  status: instance.status,
  config: instance.config,
  actor_id: user.id
}

{:ok, %{"monitor_id" => monitor_id}, _setup_invocation} =
  ApplicationOperations.invoke(
    scope,
    instance.id,
    "integrity.demo_setup",
    %{},
    approved: true
  )

wait_for_run = fn wait_for_run, run_id, attempts ->
  run = Repo.get!(Run, run_id)

  cond do
    run.status == :succeeded ->
      run

    run.status == :failed ->
      raise "integrity run failed: #{inspect(run.error)}"

    attempts == 0 ->
      raise "integrity run did not finish: #{run_id}"

    true ->
      Process.sleep(250)
      wait_for_run.(wait_for_run, run_id, attempts - 1)
  end
end

run_mode = fn mode ->
  response = Req.post!(base_url <> "/mode/#{mode}")
  unless response.status == 200, do: raise("could not set demo mode #{mode}")

  {:ok, %{"run_id" => run_id}, invocation} =
    ApplicationOperations.invoke(
      scope,
      instance.id,
      "integrity.run",
      %{"monitor_id" => monitor_id}
    )

  unless invocation.run_id == run_id,
    do: raise("Operation Invocation did not link to integrity Run")

  run = wait_for_run.(wait_for_run, run_id, 160)
  %{mode: mode, run_id: run.id, summary: run.summary}
end

runs = Enum.map(["overdue", "pending", "unavailable"], run_mode)
overview = Monitors.overview(sdk_instance)

issues =
  Enum.map(overview.issues, fn issue ->
    detail = overview.issue_details[issue.id]

    %{
      id: issue.id,
      kind: issue.kind,
      status: issue.status,
      source: issue.source.name,
      fact: issue.fact_definition.name,
      expected: detail.expected,
      observed: detail.observed,
      response_sha256: detail.evidence && detail.evidence.response_sha256,
      tool_invocation_id: detail.evidence && detail.evidence.tool_invocation_id
    }
  end)

IO.inspect(
  %{instance_id: instance.id, monitor_id: monitor_id, runs: runs, issues: issues},
  label: "Local Content Integrity proof",
  limit: :infinity
)
