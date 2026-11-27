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

    if run.monitor.scope_source_id do
      execute_collection(run)
    else
      execute_single_entity(run)
    end
  end

  # ---------------------------------------------------------------------------
  # Single-entity path (backward compatible with pre-collection monitors)
  # ---------------------------------------------------------------------------

  defp execute_single_entity(run) do
    Enum.each(run.source_checks, &start_source_check(run, &1))
    run = load_run(run.id)
    Enum.each(run.source_checks, &complete_source_check(run, &1))
    run = load_run(run.id)

    if Enum.any?(run.source_checks, &(&1.status in [:pending, :waiting_tool])) do
      wait_for_tools(run)
    else
      evaluate_single_entity(run)
    end
  end

  defp evaluate_single_entity(run) do
    repo().transaction(fn ->
      evidence =
        Evidence
        |> where([e], e.run_id == ^run.id)
        |> repo().all()
        |> Map.new(&{&1.source_id, &1})

      primary_sources = Enum.filter(run.monitor.sources, &(&1.role == :source))
      observed_at = DateTime.utc_now(:second)

      observations =
        for source <- run.monitor.sources, fact <- run.monitor.facts do
          source_check = Enum.find(run.source_checks, &(&1.source_id == source.id))
          source_evidence = evidence[source.id]
          raw_value = source_evidence && source_evidence.values[fact.key]
          normalized_value = ComparisonPolicy.normalize(raw_value, fact.comparison_type)

          {authority_value, authority_status} =
            resolve_authority(primary_sources, evidence, nil, run.source_checks, fact)

          state =
            ComparisonPolicy.evaluate(%{
              source_role: source.role,
              source_status: source_check.status,
              required: fact.required,
              value: normalized_value,
              authority_status: authority_status,
              authority_value: authority_value
            })

          observation =
            %Observation{}
            |> Observation.changeset(%{
              run_id: run.id,
              source_id: source.id,
              fact_id: fact.id,
              evidence_id: source_evidence && source_evidence.id,
              raw_value: scalar(raw_value),
              normalized_value: normalized_value,
              state: state,
              observed_at: observed_at
            })
            |> repo().insert!()

          reconcile_issue(run.monitor, source, fact, nil, observation, observed_at)
          observation
        end

      finalize_run(run, observations, nil, observed_at)
    end)
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> fail(run, reason)
    end
  end

  # ---------------------------------------------------------------------------
  # Collection path
  # ---------------------------------------------------------------------------

  defp execute_collection(run) do
    entity_ids = run.summary["entity_ids"]

    if entity_ids do
      continue_collection(run, entity_ids)
    else
      scope_source =
        Enum.find(run.monitor.sources, &(&1.id == run.monitor.scope_source_id))

      scope_check =
        Enum.find(run.source_checks, &(&1.source_id == run.monitor.scope_source_id))

      case discover_entity_ids(scope_source) do
        {:ok, []} ->
          update_check(scope_check, %{status: :failed, error: Error.map(:empty_collection, "scope_discovery")})
          fail(run, :empty_collection)

        {:ok, entity_ids} ->
          update_check(scope_check, %{status: :completed})
          run = save_entity_ids(run, entity_ids)
          start_collection_checks(run, entity_ids)

        {:error, reason} ->
          update_check(scope_check, %{status: :failed, error: Error.map(reason, "scope_discovery")})
          fail(run, :scope_discovery_failed)
      end
    end
  end

  defp discover_entity_ids(%{format: :manual} = scope_source) do
    ref_field = scope_source.ref_field || "ref"
    raw = scope_source.static_refs || "[]"

    case Jason.decode(raw) do
      {:ok, list} when is_list(list) ->
        ids =
          list
          |> Enum.map(fn item -> item[ref_field] end)
          |> Enum.reject(&is_nil/1)
          |> Enum.map(&to_string/1)

        {:ok, ids}

      _ ->
        {:error, :invalid_static_refs}
    end
  end

  defp discover_entity_ids(scope_source) do
    fetch_scope_via_http(scope_source)
  end

  defp fetch_scope_via_http(scope_source) do
    case SourceClient.fetch(scope_source) do
      {:ok, acquisition} ->
        extract_entity_ids(acquisition.document, scope_source)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_entity_ids(document, scope_source) do
    array_path = scope_source.array_path
    ref_field = scope_source.ref_field || "id"

    items =
      if array_path && array_path != "" do
        get_in(document, String.split(array_path, "."))
      else
        document
      end

    case items do
      list when is_list(list) ->
        ids =
          list
          |> Enum.map(fn item -> item[ref_field] end)
          |> Enum.reject(&is_nil/1)
          |> Enum.map(&to_string/1)

        {:ok, ids}

      _ ->
        {:error, :scope_array_not_found}
    end
  end

  defp save_entity_ids(run, entity_ids) do
    updated_summary = Map.merge(run.summary || %{}, %{"entity_ids" => entity_ids})

    run
    |> Run.status_changeset(%{summary: updated_summary})
    |> repo().update!()

    %{run | summary: updated_summary}
  end

  defp start_collection_checks(run, entity_ids) do
    data_sources = Enum.reject(run.monitor.sources, &(&1.id == run.monitor.scope_source_id))

    repo().transaction(fn ->
      for source <- data_sources, entity_id <- entity_ids do
        %SourceCheck{}
        |> SourceCheck.changeset(%{
          run_id: run.id,
          source_id: source.id,
          ref_id: entity_id,
          status: :pending
        })
        |> repo().insert!()
      end
    end)

    run = load_run(run.id)
    entity_checks = Enum.filter(run.source_checks, & &1.ref_id)
    checks_by_source = Enum.group_by(entity_checks, & &1.source_id)

    Enum.each(data_sources, fn source ->
      source_checks = Map.get(checks_by_source, source.id, [])

      case source.fetch_strategy do
        :fetch_all_entities -> start_bulk_source_checks(run, source, source_checks)
        _ -> Enum.each(source_checks, &start_entity_check(run, &1))
      end
    end)

    run = load_run(run.id)
    entity_checks = Enum.filter(run.source_checks, & &1.ref_id)
    Enum.each(entity_checks, &complete_source_check(run, &1))

    run = load_run(run.id)
    check_continuation_or_evaluate(run, entity_ids)
  end

  defp start_bulk_source_checks(_run, _source, []), do: :ok

  defp start_bulk_source_checks(run, source, checks) do
    case SourceClient.fetch(source) do
      {:ok, acquisition} ->
        ref_field = source.ref_field || "id"

        items =
          if source.array_path && source.array_path != "" do
            get_in(acquisition.document, String.split(source.array_path, "."))
          else
            acquisition.document
          end

        index =
          case items do
            list when is_list(list) ->
              Map.new(list, fn item ->
                id = item[ref_field]
                {to_string(id), item}
              end)

            _ ->
              %{}
          end

        Enum.each(checks, fn check ->
          case Map.get(index, check.ref_id) do
            nil -> fail_check(check, :entity_not_found_in_bulk_response)
            entity_data -> request_extraction(run, check, %{acquisition | document: entity_data})
          end
        end)

      {:error, reason} ->
        Enum.each(checks, &fail_check(&1, reason))
    end
  end

  defp continue_collection(run, entity_ids) do
    waiting = Enum.filter(run.source_checks, &(&1.ref_id && &1.status == :waiting_tool))
    Enum.each(waiting, &complete_source_check(run, &1))

    run = load_run(run.id)
    check_continuation_or_evaluate(run, entity_ids)
  end

  defp check_continuation_or_evaluate(run, entity_ids) do
    entity_checks = Enum.filter(run.source_checks, & &1.ref_id)

    if Enum.any?(entity_checks, &(&1.status in [:pending, :waiting_tool])) do
      wait_for_tools(run)
    else
      evaluate_collection(run, entity_ids)
    end
  end

  defp start_entity_check(_run, %SourceCheck{status: status}) when status != :pending, do: :ok

  defp start_entity_check(run, %SourceCheck{} = check) do
    source = Enum.find(run.monitor.sources, &(&1.id == check.source_id))
    url = entity_url(source, check.ref_id)

    case SourceClient.fetch(%{source | url: url}) do
      {:ok, acquisition} -> request_extraction(run, check, acquisition)
      {:error, reason} -> fail_check(check, reason)
    end
  end

  defp entity_url(%{fetch_strategy: :fetch_entity, url: url}, entity_id) when is_binary(url) do
    String.replace(url, ":ref", entity_id)
  end

  defp entity_url(%{url: url}, _entity_id), do: url

  defp evaluate_collection(run, entity_ids) do
    repo().transaction(fn ->
      evidence =
        Evidence
        |> where([e], e.run_id == ^run.id)
        |> repo().all()
        |> Map.new(&{{&1.source_id, &1.ref_id}, &1})

      data_sources = Enum.reject(run.monitor.sources, &(&1.id == run.monitor.scope_source_id))
      primary_sources = Enum.filter(data_sources, &(&1.role == :source))
      observed_at = DateTime.utc_now(:second)

      all_observations =
        Enum.flat_map(entity_ids, fn entity_id ->
          for source <- data_sources, fact <- run.monitor.facts do
            profile = Enum.find(source.target_fact_profiles, &(&1.fact_id == fact.id))
            comparison_type = (profile && profile.comparison_type) || fact.comparison_type
            pattern = profile && profile.pattern

            source_check = find_entity_check(run.source_checks, source.id, entity_id)
            source_evidence = evidence[{source.id, entity_id}]
            raw_value = source_evidence && source_evidence.values[fact.key]
            normalized_value = ComparisonPolicy.normalize(raw_value, comparison_type)

            {authority_value, authority_status} =
              resolve_authority(primary_sources, evidence, entity_id, run.source_checks, fact, comparison_type)

            state =
              ComparisonPolicy.evaluate(%{
                source_role: source.role,
                source_status: (source_check && source_check.status) || :failed,
                required: fact.required,
                value: normalized_value,
                authority_status: authority_status,
                authority_value: authority_value,
                comparison_type: comparison_type,
                pattern: pattern
              })

            observation =
              %Observation{}
              |> Observation.changeset(%{
                run_id: run.id,
                source_id: source.id,
                fact_id: fact.id,
                evidence_id: source_evidence && source_evidence.id,
                ref_id: entity_id,
                raw_value: scalar(raw_value),
                normalized_value: normalized_value,
                state: state,
                observed_at: observed_at
              })
              |> repo().insert!()

            reconcile_issue(run.monitor, source, fact, entity_id, observation, observed_at)
            observation
          end
        end)

      finalize_run(run, all_observations, entity_ids, observed_at)
    end)
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> fail(run, reason)
    end
  end

  # ---------------------------------------------------------------------------
  # Shared — source check acquisition and tool invocation
  # ---------------------------------------------------------------------------

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
            ref_id: check.ref_id,
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

  # ---------------------------------------------------------------------------
  # Issue reconciliation
  # ---------------------------------------------------------------------------

  defp reconcile_issue(monitor, source, fact, entity_id, observation, now)
       when observation.state in [:healthy, :pending] do
    unresolved_issues(monitor.id, source.id, fact.id, entity_id)
    |> Enum.each(fn issue ->
      issue
      |> Issue.changeset(%{status: :resolved, resolved_at: now, last_seen_at: now})
      |> repo().update!()
    end)
  end

  defp reconcile_issue(_monitor, _source, _fact, _entity_id, %{state: :unknown}, _now), do: :ok

  defp reconcile_issue(monitor, source, fact, entity_id, observation, now) do
    existing = unresolved_issues(monitor.id, source.id, fact.id, entity_id)

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

        entity_label = if entity_id, do: " [#{entity_id}]", else: ""

        %Issue{}
        |> Issue.changeset(%{
          monitor_id: monitor.id,
          source_id: source.id,
          fact_id: fact.id,
          current_observation_id: observation.id,
          ref_id: entity_id,
          kind: observation.state,
          status: :open,
          summary:
            "#{fact.name} is #{humanize(observation.state)} in #{source.name}#{entity_label}",
          occurrence_count: 1,
          first_seen_at: now,
          last_seen_at: now
        })
        |> repo().insert!()
    end
  end

  defp unresolved_issues(monitor_id, source_id, fact_id, nil) do
    Issue
    |> where(
      [i],
      i.monitor_id == ^monitor_id and i.source_id == ^source_id and
        i.fact_id == ^fact_id and is_nil(i.ref_id) and
        i.status in [:open, :acknowledged]
    )
    |> repo().all()
  end

  defp unresolved_issues(monitor_id, source_id, fact_id, entity_id) do
    Issue
    |> where(
      [i],
      i.monitor_id == ^monitor_id and i.source_id == ^source_id and
        i.fact_id == ^fact_id and i.ref_id == ^entity_id and
        i.status in [:open, :acknowledged]
    )
    |> repo().all()
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp finalize_run(run, observations, entity_ids, observed_at) do
    summary =
      Map.merge(run.summary || %{}, %{
        "entity_ids" => entity_ids,
        "observations" => length(observations),
        "states" => observations |> Enum.frequencies_by(&to_string(&1.state)),
        "open_issues" => count_open_issues(run.monitor_id)
      })

    run
    |> Run.status_changeset(%{
      status: :succeeded,
      summary: summary,
      error: nil,
      completed_at: observed_at
    })
    |> repo().update!()
  end

  defp count_open_issues(monitor_id) do
    repo().aggregate(
      from(i in Issue,
        where: i.monitor_id == ^monitor_id and i.status in [:open, :acknowledged]
      ),
      :count
    )
  end

  defp find_entity_check(source_checks, source_id, entity_id) do
    Enum.find(source_checks, &(&1.source_id == source_id && &1.ref_id == entity_id))
  end

  defp scalar(value) when is_binary(value), do: value
  defp scalar(value) when is_number(value) or is_boolean(value), do: to_string(value)
  defp scalar(_value), do: nil

  defp fail_check(check, reason),
    do: update_check(check, %{status: :failed, error: Error.map(reason, "source_check_failed")})

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

  defp mark_running(run) do
    run
    |> Run.status_changeset(%{
      status: :running,
      started_at: run.started_at || DateTime.utc_now(:second),
      error: nil
    })
    |> repo().update!()
    |> repo().preload(
      [monitor: [:sources, :facts], source_checks: [:source]],
      force: true
    )
  end

  defp load_run(id) do
    Run
    |> repo().get(id)
    |> case do
      nil ->
        nil

      run ->
        repo().preload(
          run,
          [monitor: [:facts, sources: :target_fact_profiles], source_checks: [:source]],
          force: true
        )
    end
  end

  defp resolve_authority(primary_sources, evidence, entity_id, source_checks, fact, comparison_type \\ :text) do
    owner = Enum.find(primary_sources, fn p ->
      Map.get(p.mappings || %{}, fact.key) not in [nil, ""]
    end)

    case owner do
      nil ->
        {nil, :completed}

      primary ->
        check =
          if entity_id,
            do: find_entity_check(source_checks, primary.id, entity_id),
            else: Enum.find(source_checks, &(&1.source_id == primary.id))

        ev =
          if entity_id,
            do: evidence[{primary.id, entity_id}],
            else: evidence[primary.id]

        raw_value = ev && ev.values[fact.key]
        normalized = ComparisonPolicy.normalize(raw_value, comparison_type)
        status = (check && check.status) || :failed
        {normalized, status}
    end
  end

  defp humanize(value), do: value |> to_string() |> String.replace("_", " ")
  defp repo, do: Runtime.repo!()
end
