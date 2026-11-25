defmodule Contexla.Applications.ContentIntegrityMonitor.Executor do
  @moduledoc "Executes one durable, evidence-backed content-integrity Run."

  import Ecto.Query, warn: false

  alias Contexla.Applications.Sdk.{Error, Runtime}

  alias Contexla.Applications.ContentIntegrityMonitor.{
    ComparisonPolicy,
    Evidence,
    Issue,
    Observation,
    Run,
    SourceCheck,
    SourceClient
  }

  alias Contexla.Applications.ContentIntegrityMonitor.Workers.RunWorker

  def perform(run_id) do
    case load_run(run_id) do
      nil -> {:discard, :integrity_run_not_found}
      %Run{status: :succeeded} -> :ok
      %Run{status: :failed} -> :ok
      run -> execute_safely(run)
    end
  end

  defp execute_safely(run) do
    execute(run)
  rescue
    _error -> fail(run, :integrity_run_exception)
  catch
    kind, reason -> fail(run, {kind, reason})
  end

  defp execute(run) do
    run = mark_running(run)
    Enum.each(run.source_checks, &start_source_check(run, &1))
    run = load_run(run.id)
    Enum.each(run.source_checks, &complete_source_check(run, &1))
    run = load_run(run.id)

    cond do
      Enum.any?(run.source_checks, &(&1.status in [:pending, :waiting_tool])) ->
        wait_for_tools(run)

      true ->
        evaluate(run)
    end
  end

  defp start_source_check(_run, %SourceCheck{status: status}) when status != :pending, do: :ok

  defp start_source_check(run, %SourceCheck{} = check) do
    case SourceClient.fetch(check.source) do
      {:ok, acquisition} -> request_extraction(run, check, acquisition)
      {:error, reason} -> fail_check(check, reason)
    end
  end

  defp request_extraction(run, check, acquisition) do
    {tool_id, input} = extraction_request(check.source, acquisition.document)

    case Runtime.request_tool(
           run.initiated_by_user_id,
           run.application_instance_id,
           tool_id,
           "1.0.0",
           input,
           parent_run_id: run.id
         ) do
      {:ok, invocation} ->
        update_check(check, %{
          status: :waiting_tool,
          tool_invocation_id: invocation.id,
          http_status: acquisition.status,
          fetched_at: acquisition.fetched_at,
          response_sha256: acquisition.sha256,
          media_type: acquisition.media_type,
          excerpt: acquisition.excerpt,
          error: nil
        })

      {:error, reason} ->
        fail_check(check, {:tool_request_failed, reason})
    end
  end

  defp extraction_request(%{format: :json, mappings: mappings}, document) do
    {"com.contexla.extract.json-values", %{"document" => document, "mappings" => mappings}}
  end

  defp extraction_request(%{format: :html, mappings: mappings}, document) do
    {"com.contexla.extract.html-values", %{"html" => document, "mappings" => mappings}}
  end

  defp complete_source_check(_run, %SourceCheck{status: status}) when status != :waiting_tool,
    do: :ok

  defp complete_source_check(run, %SourceCheck{} = check) do
    case Runtime.get_tool_invocation(
           run.initiated_by_user_id,
           run.application_instance_id,
           check.tool_invocation_id
         ) do
      {:ok, %{status: status}} when status in [:pending, :running] ->
        :ok

      {:ok, %{status: :succeeded, output: %{"values" => values}}} ->
        repo().transaction(fn ->
          %Evidence{}
          |> Evidence.changeset(%{
            run_id: run.id,
            source_id: check.source_id,
            tool_invocation_id: check.tool_invocation_id,
            response_sha256: check.response_sha256,
            media_type: check.media_type,
            excerpt: check.excerpt,
            values: values,
            observed_at: check.fetched_at
          })
          |> repo().insert!()

          update_check(check, %{status: :completed, error: nil})
        end)

      {:ok, %{status: status}} when status in [:failed, :timed_out, :cancelled] ->
        fail_check(check, {:tool_execution_failed, status})

      {:ok, _invocation} ->
        fail_check(check, :invalid_tool_result)

      {:error, reason} ->
        fail_check(check, {:tool_invocation_unavailable, reason})
    end
  end

  defp wait_for_tools(run) do
    run
    |> Run.status_changeset(%{status: :waiting_tools})
    |> repo().update!()

    case Runtime.enqueue(RunWorker, %{"integrity_run_id" => run.id}, schedule_in: 1) do
      {:ok, _job} -> :ok
      {:error, reason} -> fail(run, {:continuation_enqueue_failed, reason})
    end
  end

  defp evaluate(run) do
    repo().transaction(fn ->
      evidence =
        Evidence
        |> where([item], item.run_id == ^run.id)
        |> repo().all()
        |> Map.new(&{&1.source_id, &1})

      authority = Enum.find(run.monitor.sources, &(&1.role == :authority))
      authority_evidence = evidence[authority.id]
      authority_check = Enum.find(run.source_checks, &(&1.source_id == authority.id))
      authority_updated_at = ComparisonPolicy.source_updated_at(authority_evidence)
      observed_at = DateTime.utc_now(:second)

      observations =
        for source <- run.monitor.sources,
            fact <- run.monitor.facts do
          source_check = Enum.find(run.source_checks, &(&1.source_id == source.id))
          source_evidence = evidence[source.id]
          raw_value = source_evidence && source_evidence.values[fact.key]
          normalized_value = ComparisonPolicy.normalize(raw_value)

          authority_value =
            authority_evidence && ComparisonPolicy.normalize(authority_evidence.values[fact.key])

          state =
            ComparisonPolicy.evaluate(%{
              source_role: source.role,
              source_status: source_check.status,
              required: fact.required,
              value: normalized_value,
              authority_status: authority_check.status,
              authority_value: authority_value,
              allowed_delay_seconds: source.allowed_delay_seconds,
              authority_updated_at: authority_updated_at,
              now: observed_at
            })

          observation =
            %Observation{}
            |> Observation.changeset(%{
              run_id: run.id,
              source_id: source.id,
              fact_definition_id: fact.id,
              evidence_id: source_evidence && source_evidence.id,
              raw_value: scalar(raw_value),
              normalized_value: normalized_value,
              state: state,
              source_updated_at: ComparisonPolicy.source_updated_at(source_evidence),
              observed_at: observed_at
            })
            |> repo().insert!()

          reconcile_issue(run.monitor, source, fact, observation, observed_at)
          observation
        end

      summary = %{
        "observations" => length(observations),
        "states" => observations |> Enum.frequencies_by(&to_string(&1.state)),
        "open_issues" =>
          repo().aggregate(
            from(issue in Issue,
              where:
                issue.monitor_id == ^run.monitor_id and issue.status in [:open, :acknowledged]
            ),
            :count
          )
      }

      run
      |> Run.status_changeset(%{
        status: :succeeded,
        summary: summary,
        error: nil,
        completed_at: observed_at
      })
      |> repo().update!()
    end)
    |> case do
      {:ok, _run} -> :ok
      {:error, reason} -> fail(run, reason)
    end
  end

  defp reconcile_issue(monitor, source, fact, observation, now)
       when observation.state in [:healthy, :pending] do
    unresolved_issues(monitor.id, source.id, fact.id)
    |> Enum.each(fn issue ->
      issue
      |> Issue.changeset(%{status: :resolved, resolved_at: now, last_seen_at: now})
      |> repo().update!()
    end)
  end

  defp reconcile_issue(_monitor, _source, _fact, %{state: :unknown}, _now), do: :ok

  defp reconcile_issue(monitor, source, fact, observation, now) do
    existing = unresolved_issues(monitor.id, source.id, fact.id)

    case Enum.find(existing, &(&1.kind == observation.state)) do
      %Issue{} = issue ->
        issue
        |> Issue.changeset(%{
          current_observation_id: observation.id,
          occurrence_count: issue.occurrence_count + 1,
          last_seen_at: now
        })
        |> repo().update!()

      nil ->
        Enum.each(existing, fn issue ->
          issue
          |> Issue.changeset(%{status: :resolved, resolved_at: now, last_seen_at: now})
          |> repo().update!()
        end)

        %Issue{}
        |> Issue.changeset(%{
          monitor_id: monitor.id,
          source_id: source.id,
          fact_definition_id: fact.id,
          current_observation_id: observation.id,
          kind: observation.state,
          status: :open,
          summary: "#{fact.name} is #{humanize(observation.state)} in #{source.name}",
          occurrence_count: 1,
          first_seen_at: now,
          last_seen_at: now
        })
        |> repo().insert!()
    end
  end

  defp unresolved_issues(monitor_id, source_id, fact_id) do
    Issue
    |> where(
      [issue],
      issue.monitor_id == ^monitor_id and issue.source_id == ^source_id and
        issue.fact_definition_id == ^fact_id and issue.status in [:open, :acknowledged]
    )
    |> repo().all()
  end

  defp scalar(value) when is_binary(value), do: value
  defp scalar(value) when is_number(value) or is_boolean(value), do: to_string(value)
  defp scalar(_value), do: nil

  defp mark_running(run) do
    run
    |> Run.status_changeset(%{
      status: :running,
      started_at: run.started_at || DateTime.utc_now(:second),
      error: nil
    })
    |> repo().update!()
    |> repo().preload(monitor: [:sources, :facts], source_checks: [:source])
  end

  defp fail_check(check, reason) do
    update_check(check, %{status: :failed, error: Error.map(reason, "source_check_failed")})
  end

  defp update_check(check, attrs),
    do: check |> SourceCheck.changeset(attrs) |> repo().update!()

  defp fail(run, reason) do
    run
    |> Run.status_changeset(%{
      status: :failed,
      error: Error.map(reason, "integrity_run_failed"),
      completed_at: DateTime.utc_now(:second)
    })
    |> repo().update()

    {:error, reason}
  end

  defp load_run(id) do
    Run
    |> repo().get(id)
    |> case do
      nil ->
        nil

      run ->
        repo().preload(run, [monitor: [:sources, :facts], source_checks: [:source]], force: true)
    end
  end

  defp humanize(value), do: value |> to_string() |> String.replace("_", " ")
  defp repo, do: Runtime.repo!()
end
