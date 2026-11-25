defmodule Contexla.Applications.ContentIntegrityMonitor.Monitors do
  @moduledoc "Application services for configuring and running integrity Monitors."

  import Ecto.Query, warn: false

  alias Contexla.Applications.Sdk.{Instance, Runtime}

  alias Contexla.Applications.ContentIntegrityMonitor.{
    FactDefinition,
    Issue,
    Monitor,
    Observation,
    Run,
    Source,
    SourceCheck
  }

  alias Contexla.Applications.ContentIntegrityMonitor.Workers.RunWorker

  @application_id "com.contexla.application.content-integrity-monitor"

  def create_demo(%Instance{} = instance) do
    with :ok <- ensure_instance(instance) do
      case repo().get_by(Monitor,
             application_instance_id: instance.id,
             name: "Program content delivery"
           ) do
        %Monitor{} = monitor -> {:ok, %{"monitor_id" => monitor.id, "created" => false}}
        nil -> insert_demo(instance)
      end
    end
  end

  def start_run(%Instance{} = instance, monitor_id) do
    with :ok <- ensure_instance(instance),
         %Monitor{} = monitor <-
           repo().get_by(Monitor,
             id: monitor_id,
             application_instance_id: instance.id,
             status: :active
           ) do
      monitor = repo().preload(monitor, [:sources, :facts])

      repo().transaction(fn ->
        run =
          %Run{}
          |> Run.create_changeset(%{
            monitor_id: monitor.id,
            application_instance_id: instance.id,
            initiated_by_user_id: instance.actor_id,
            status: :queued
          })
          |> repo().insert!()

        Enum.each(monitor.sources, fn source ->
          %SourceCheck{}
          |> SourceCheck.changeset(%{run_id: run.id, source_id: source.id, status: :pending})
          |> repo().insert!()
        end)

        {:ok, _job} = Runtime.enqueue(RunWorker, %{"integrity_run_id" => run.id})
        run
      end)
    else
      nil -> {:error, :monitor_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def overview(%Instance{} = instance) do
    monitors =
      Monitor
      |> where([monitor], monitor.application_instance_id == ^instance.id)
      |> order_by([monitor], asc: monitor.name)
      |> preload([:sources, :facts])
      |> repo().all()

    monitor_ids = Enum.map(monitors, & &1.id)

    runs =
      Run
      |> where([run], run.application_instance_id == ^instance.id)
      |> order_by([run], desc: run.inserted_at)
      |> limit(20)
      |> preload(:monitor)
      |> repo().all()

    issues =
      Issue
      |> where([issue], issue.monitor_id in ^monitor_ids)
      |> order_by([issue], asc: issue.status, desc: issue.last_seen_at)
      |> preload([:monitor, :source, :fact_definition, current_observation: [:evidence]])
      |> repo().all()

    %{
      monitors: monitors,
      runs: runs,
      issues: issues,
      issue_details: issue_details(monitors, issues),
      matrices: latest_matrices(monitors),
      active_runs: active_runs(runs)
    }
  end

  def transition_issue(%Instance{} = instance, issue_id, target)
      when target in [:acknowledged, :resolved] do
    with :ok <- ensure_instance(instance),
         %Issue{} = issue <- scoped_issue(instance.id, issue_id),
         :ok <- valid_transition(issue.status, target) do
      attrs =
        case target do
          :acknowledged -> %{status: :acknowledged, resolved_at: nil}
          :resolved -> %{status: :resolved, resolved_at: DateTime.utc_now(:second)}
        end

      case issue |> Issue.changeset(attrs) |> repo().update() do
        {:ok, updated} ->
          {:ok, %{"issue_id" => updated.id, "status" => to_string(updated.status)}}

        {:error, _changeset} ->
          {:error, :issue_transition_failed}
      end
    else
      nil -> {:error, :issue_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_demo(instance) do
    base_url = instance.config["demo_base_url"] || "http://localhost:4205"

    repo().transaction(fn ->
      monitor =
        %Monitor{}
        |> Monitor.changeset(%{
          application_instance_id: instance.id,
          name: "Program content delivery",
          entity_key: "program:PN123",
          status: :active
        })
        |> repo().insert!()

      Enum.each(demo_facts(), fn attrs ->
        %FactDefinition{}
        |> FactDefinition.changeset(Map.put(attrs, :monitor_id, monitor.id))
        |> repo().insert!()
      end)

      Enum.each(demo_sources(base_url), fn attrs ->
        %Source{}
        |> Source.changeset(Map.put(attrs, :monitor_id, monitor.id))
        |> repo().insert!()
      end)

      %{"monitor_id" => monitor.id, "created" => true}
    end)
  end

  defp demo_facts do
    [
      %{key: "program_name", name: "Program name", required: true},
      %{key: "credential", name: "Credential", required: true},
      %{key: "duration", name: "Duration", required: true}
    ]
  end

  defp demo_sources(base_url) do
    json_mappings = %{
      "program_name" => "program.name",
      "credential" => "program.credential",
      "duration" => "program.duration",
      "_updated_at" => "program.updated_at"
    }

    html_mappings = %{
      "program_name" => "[data-field=program-name]",
      "credential" => "[data-field=credential]",
      "duration" => "[data-field=duration]",
      "_updated_at" => "[data-field=updated-at]"
    }

    [
      source(
        "authority",
        "Authoritative program API",
        :authority,
        :json,
        base_url <> "/authority/programs/PN123",
        json_mappings,
        0
      ),
      source(
        "delivery",
        "Delivery API",
        :representation,
        :json,
        base_url <> "/delivery/programs/PN123",
        json_mappings,
        3_600
      ),
      source(
        "website",
        "Public program page",
        :representation,
        :html,
        base_url <> "/programs/PN123",
        html_mappings,
        7_200
      ),
      source(
        "search",
        "Program search",
        :representation,
        :html,
        base_url <> "/search/programs/PN123",
        html_mappings,
        10_800
      )
    ]
  end

  defp source(key, name, role, format, url, mappings, delay) do
    %{
      key: key,
      name: name,
      role: role,
      format: format,
      url: url,
      mappings: mappings,
      allowed_delay_seconds: delay
    }
  end

  defp scoped_issue(instance_id, issue_id) do
    Issue
    |> join(:inner, [issue], monitor in Monitor, on: monitor.id == issue.monitor_id)
    |> where(
      [issue, monitor],
      issue.id == ^issue_id and monitor.application_instance_id == ^instance_id
    )
    |> repo().one()
  end

  defp issue_details(monitors, issues) do
    authority_source_ids =
      monitors
      |> Enum.flat_map(& &1.sources)
      |> Enum.filter(&(&1.role == :authority))
      |> Map.new(&{&1.monitor_id, &1.id})

    current_observations =
      issues
      |> Enum.map(& &1.current_observation)
      |> Enum.reject(&is_nil/1)

    authority_observations =
      case current_observations do
        [] ->
          []

        observations ->
          run_ids = Enum.map(observations, & &1.run_id)
          fact_ids = Enum.map(observations, & &1.fact_definition_id)
          source_ids = Map.values(authority_source_ids)

          Observation
          |> where(
            [observation],
            observation.run_id in ^run_ids and observation.fact_definition_id in ^fact_ids and
              observation.source_id in ^source_ids
          )
          |> preload(:evidence)
          |> repo().all()
      end
      |> Map.new(&{{&1.run_id, &1.fact_definition_id}, &1})

    Map.new(issues, fn issue ->
      current = issue.current_observation

      authority =
        current && authority_observations[{current.run_id, current.fact_definition_id}]

      {issue.id,
       %{
         expected: authority && authority.normalized_value,
         observed: current && current.normalized_value,
         observed_at: current && current.observed_at,
         source_updated_at: current && current.source_updated_at,
         evidence: current && current.evidence
       }}
    end)
  end

  defp latest_matrices([]), do: %{}

  defp latest_matrices(monitors) do
    monitor_ids = Enum.map(monitors, & &1.id)

    succeeded_runs =
      Run
      |> where([r], r.monitor_id in ^monitor_ids and r.status == :succeeded)
      |> order_by([r], desc: r.completed_at)
      |> repo().all()

    last_runs =
      Enum.reduce(succeeded_runs, %{}, fn run, acc ->
        Map.put_new(acc, run.monitor_id, run)
      end)

    run_ids = last_runs |> Map.values() |> Enum.map(& &1.id)

    cells_by_run =
      if run_ids == [] do
        %{}
      else
        Observation
        |> where([o], o.run_id in ^run_ids)
        |> repo().all()
        |> Enum.group_by(& &1.run_id)
        |> Map.new(fn {run_id, obs} ->
          {run_id, Map.new(obs, &{{&1.source_id, &1.fact_definition_id}, &1})}
        end)
      end

    Map.new(monitors, fn monitor ->
      run = last_runs[monitor.id]
      cells = if run, do: Map.get(cells_by_run, run.id, %{}), else: %{}

      sources =
        Enum.sort_by(monitor.sources, fn s ->
          {if(s.role == :authority, do: 0, else: 1), s.name}
        end)

      facts = Enum.sort_by(monitor.facts, & &1.name)
      authority_id = Enum.find_value(sources, fn s -> if s.role == :authority, do: s.id end)

      {monitor.id,
       %{run: run, sources: sources, facts: facts, cells: cells, authority_id: authority_id}}
    end)
  end

  defp active_runs(runs) do
    runs
    |> Enum.filter(&(&1.status in [:queued, :running, :waiting_tools]))
    |> Enum.reduce(%{}, fn run, acc -> Map.put_new(acc, run.monitor_id, run) end)
  end

  defp valid_transition(:open, :acknowledged), do: :ok
  defp valid_transition(status, :resolved) when status in [:open, :acknowledged], do: :ok
  defp valid_transition(status, status), do: :ok
  defp valid_transition(_current, _target), do: {:error, :invalid_issue_transition}

  defp ensure_instance(%Instance{application_id: @application_id}), do: :ok
  defp ensure_instance(_instance), do: {:error, :wrong_application}
  defp repo, do: Runtime.repo!()
end
