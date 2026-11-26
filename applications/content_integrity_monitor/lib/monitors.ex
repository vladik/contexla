defmodule Contexla.Applications.ContentIntegrityMonitor.Monitors do
  @moduledoc "Application services for configuring and running integrity Monitors."

  import Ecto.Query, warn: false

  alias Contexla.Applications.Sdk.{Instance, Runtime}

  alias Contexla.Applications.ContentIntegrityMonitor.{
    Fact,
    Issue,
    Monitor,
    Observation,
    Run,
    ScheduleWindow,
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
      sq = sorted_sources_query()
      monitor = repo().preload(monitor, [:facts, sources: sq])

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

        if monitor.scope_source_id do
          scope_source = Enum.find(monitor.sources, &(&1.id == monitor.scope_source_id))

          if scope_source do
            %SourceCheck{}
            |> SourceCheck.changeset(%{run_id: run.id, source_id: scope_source.id, status: :pending})
            |> repo().insert!()
          end
        else
          Enum.each(monitor.sources, fn source ->
            %SourceCheck{}
            |> SourceCheck.changeset(%{run_id: run.id, source_id: source.id, status: :pending})
            |> repo().insert!()
          end)
        end

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
      |> where([m], m.application_instance_id == ^instance.id)
      |> order_by([m], asc: m.name)
      |> preload([:facts, sources: ^sorted_sources_query()])
      |> repo().all()

    monitor_ids = Enum.map(monitors, & &1.id)

    runs =
      Run
      |> where([r], r.application_instance_id == ^instance.id)
      |> order_by([r], desc: r.inserted_at)
      |> limit(20)
      |> preload(:monitor)
      |> repo().all()

    issues =
      Issue
      |> where([i], i.monitor_id in ^monitor_ids)
      |> order_by([i], asc: i.status, desc: i.last_seen_at)
      |> preload([:monitor, :source, :fact, current_observation: [:evidence]])
      |> repo().all()

    collection_monitors = Enum.filter(monitors, & &1.scope_source_id)
    single_monitors = Enum.reject(monitors, & &1.scope_source_id)

    %{
      monitors: monitors,
      runs: runs,
      issues: issues,
      issue_details: issue_details(monitors, issues),
      matrices: latest_matrices(single_monitors),
      summaries: latest_summaries(collection_monitors),
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

  def in_maintenance_window?(%Monitor{schedule_windows: %Ecto.Association.NotLoaded{}} = monitor) do
    monitor = repo().preload(monitor, :schedule_windows)
    in_maintenance_window?(monitor)
  end

  def in_maintenance_window?(%Monitor{schedule_windows: windows}) do
    ScheduleWindow.any_active?(windows)
  end

  # ---------------------------------------------------------------------------
  # Monitor management CRUD
  # ---------------------------------------------------------------------------

  def list_monitors(%Instance{} = instance) do
    Monitor
    |> where([m], m.application_instance_id == ^instance.id)
    |> where([m], m.status != :archived)
    |> order_by([m], asc: m.name)
    |> repo().all()
  end

  def list_archived_monitors(%Instance{} = instance) do
    Monitor
    |> where([m], m.application_instance_id == ^instance.id)
    |> where([m], m.status == :archived)
    |> order_by([m], asc: m.name)
    |> repo().all()
  end

  def get_monitor(%Instance{} = instance, monitor_id) do
    case repo().get_by(Monitor, id: monitor_id, application_instance_id: instance.id) do
      nil -> {:error, :not_found}
      monitor -> {:ok, repo().preload(monitor, [:facts, :schedule_windows, sources: sorted_sources_query()])}
    end
  end

  def monitor_has_runs?(%Instance{} = instance, monitor_id) do
    case repo().get_by(Monitor, id: monitor_id, application_instance_id: instance.id) do
      nil ->
        false

      monitor ->
        Run
        |> where([r], r.monitor_id == ^monitor.id)
        |> repo().exists?()
    end
  end

  def create_monitor(%Instance{} = instance, attrs) do
    with :ok <- ensure_instance(instance) do
      attrs = Map.put(attrs, "application_instance_id", instance.id)

      case %Monitor{} |> Monitor.changeset(attrs) |> repo().insert() do
        {:ok, monitor} -> {:ok, repo().preload(monitor, [:facts, :schedule_windows, sources: sorted_sources_query()])}
        error -> error
      end
    end
  end

  def update_monitor(%Instance{} = instance, monitor_id, attrs) do
    with :ok <- ensure_instance(instance),
         {:ok, monitor} <- get_monitor(instance, monitor_id) do
      case monitor |> Monitor.changeset(attrs) |> repo().update() do
        {:ok, updated} -> {:ok, repo().preload(updated, [:facts, :schedule_windows, sources: sorted_sources_query()])}
        error -> error
      end
    end
  end

  def delete_monitor(%Instance{} = instance, monitor_id) do
    with :ok <- ensure_instance(instance),
         {:ok, monitor} <- get_monitor(instance, monitor_id) do
      has_runs =
        Run
        |> where([r], r.monitor_id == ^monitor.id)
        |> repo().exists?()

      if has_runs do
        {:error, :has_runs}
      else
        case repo().delete(monitor) do
          {:ok, _} -> :ok
          {:error, cs} -> {:error, cs}
        end
      end
    end
  end

  def archive_monitor(%Instance{} = instance, monitor_id) do
    with :ok <- ensure_instance(instance),
         {:ok, monitor} <- get_monitor(instance, monitor_id) do
      monitor
      |> Monitor.changeset(%{status: :archived})
      |> repo().update()
      |> case do
        {:ok, _} -> :ok
        {:error, cs} -> {:error, cs}
      end
    end
  end

  def restore_monitor(%Instance{} = instance, monitor_id) do
    with :ok <- ensure_instance(instance) do
      case repo().get_by(Monitor, id: monitor_id, application_instance_id: instance.id) do
        nil ->
          {:error, :not_found}

        monitor ->
          monitor
          |> Monitor.changeset(%{status: :active})
          |> repo().update()
          |> case do
            {:ok, _} -> :ok
            {:error, cs} -> {:error, cs}
          end
      end
    end
  end

  def add_source(%Instance{} = instance, monitor_id, attrs) do
    with :ok <- ensure_instance(instance) do
      case repo().get_by(Monitor, id: monitor_id, application_instance_id: instance.id) do
        nil ->
          {:error, :not_found}

        monitor ->
          attrs = attrs |> normalize_source_attrs() |> Map.put("monitor_id", monitor.id)
          role = attrs["role"] |> then(&if is_binary(&1), do: String.to_existing_atom(&1), else: &1)

          max_order =
            Source
            |> where([s], s.monitor_id == ^monitor.id and s.role == ^role)
            |> select([s], max(s.sort_order))
            |> repo().one()

          attrs = Map.put(attrs, "sort_order", (max_order || -1) + 1)

          case %Source{} |> Source.changeset(attrs) |> repo().insert() do
            {:ok, source} ->
              if source.role == :scope do
                monitor
                |> Monitor.changeset(%{scope_source_id: source.id})
                |> repo().update!()
              end

              {:ok, source}

            error ->
              error
          end
      end
    end
  end

  def update_source(%Instance{} = instance, source_id, attrs) do
    with :ok <- ensure_instance(instance) do
      case scoped_source(instance.id, source_id) do
        nil ->
          {:error, :not_found}

        source ->
          old_role = source.role
          attrs = normalize_source_attrs(attrs)

          case source |> Source.changeset(attrs) |> repo().update() do
            {:ok, updated} ->
              monitor = repo().get!(Monitor, updated.monitor_id)

              cond do
                updated.role == :scope ->
                  monitor
                  |> Monitor.changeset(%{scope_source_id: updated.id})
                  |> repo().update!()

                old_role == :scope and monitor.scope_source_id == updated.id ->
                  monitor
                  |> Monitor.changeset(%{scope_source_id: nil})
                  |> repo().update!()

                true ->
                  :ok
              end

              {:ok, updated}

            error ->
              error
          end
      end
    end
  end

  def delete_source(%Instance{} = instance, source_id) do
    with :ok <- ensure_instance(instance) do
      case scoped_source(instance.id, source_id) do
        nil ->
          {:error, :not_found}

        source ->
          monitor = repo().get!(Monitor, source.monitor_id)

          case repo().delete(source) do
            {:ok, _} ->
              if monitor.scope_source_id == source.id do
                monitor
                |> Monitor.changeset(%{scope_source_id: nil})
                |> repo().update!()
              end

              :ok

            {:error, cs} ->
              {:error, cs}
          end
      end
    end
  end

  def move_source(%Instance{} = instance, source_id, direction) when direction in [:up, :down] do
    with :ok <- ensure_instance(instance) do
      case scoped_source(instance.id, source_id) do
        nil ->
          {:error, :not_found}

        source ->
          siblings =
            Source
            |> where([s], s.monitor_id == ^source.monitor_id and s.role == ^source.role)
            |> order_by([s], [asc: s.sort_order, asc: s.inserted_at])
            |> repo().all()

          idx = Enum.find_index(siblings, &(&1.id == source.id))
          new_idx = if direction == :up, do: idx - 1, else: idx + 1

          if new_idx >= 0 and new_idx < length(siblings) do
            reordered =
              siblings
              |> List.delete_at(idx)
              |> List.insert_at(new_idx, source)

            repo().transaction(fn ->
              Enum.each(Enum.with_index(reordered), fn {s, i} ->
                s |> Source.changeset(%{sort_order: i}) |> repo().update!()
              end)
            end)
          end

          :ok
      end
    end
  end

  def add_fact(%Instance{} = instance, monitor_id, attrs) do
    with :ok <- ensure_instance(instance) do
      case repo().get_by(Monitor, id: monitor_id, application_instance_id: instance.id) do
        nil ->
          {:error, :not_found}

        monitor ->
          attrs = Map.put(attrs, "monitor_id", monitor.id)

          %Fact{}
          |> Fact.changeset(attrs)
          |> repo().insert()
      end
    end
  end

  def update_fact(%Instance{} = instance, fact_id, attrs) do
    with :ok <- ensure_instance(instance) do
      case scoped_fact(instance.id, fact_id) do
        nil -> {:error, :not_found}
        fact -> fact |> Fact.changeset(attrs) |> repo().update()
      end
    end
  end

  def delete_fact(%Instance{} = instance, fact_id) do
    with :ok <- ensure_instance(instance) do
      case scoped_fact(instance.id, fact_id) do
        nil ->
          {:error, :not_found}

        fact ->
          case repo().delete(fact) do
            {:ok, _} -> :ok
            error -> error
          end
      end
    end
  end

  def add_schedule_window(%Instance{} = instance, monitor_id, attrs) do
    with :ok <- ensure_instance(instance) do
      case repo().get_by(Monitor, id: monitor_id, application_instance_id: instance.id) do
        nil ->
          {:error, :not_found}

        monitor ->
          attrs = Map.put(attrs, "monitor_id", monitor.id)

          %ScheduleWindow{}
          |> ScheduleWindow.changeset(attrs)
          |> repo().insert()
      end
    end
  end

  def delete_schedule_window(%Instance{} = instance, window_id) do
    with :ok <- ensure_instance(instance) do
      case scoped_window(instance.id, window_id) do
        nil ->
          {:error, :not_found}

        window ->
          case repo().delete(window) do
            {:ok, _} -> :ok
            error -> error
          end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Demo setup
  # ---------------------------------------------------------------------------

  defp insert_demo(instance) do
    base_url = "http://localhost:4205"

    repo().transaction(fn ->
      monitor =
        %Monitor{}
        |> Monitor.changeset(%{
          application_instance_id: instance.id,
          name: "Program content delivery",
          entity_type: "programs",
          status: :active
        })
        |> repo().insert!()

      Enum.each(demo_facts(), fn attrs ->
        %Fact{}
        |> Fact.changeset(Map.put(attrs, :monitor_id, monitor.id))
        |> repo().insert!()
      end)

      scope_source =
        %Source{}
        |> Source.changeset(%{
          monitor_id: monitor.id,
          key: "scope",
          name: "Program catalog (scope)",
          role: :scope,
          format: :json,
          fetch_strategy: :fetch_all_entities,
          url: base_url <> "/scope/programs",
          array_path: "programs",
          id_field: "id",
          mappings: %{}
        })
        |> repo().insert!()

      Enum.each(demo_data_sources(base_url), fn attrs ->
        %Source{}
        |> Source.changeset(Map.put(attrs, :monitor_id, monitor.id))
        |> repo().insert!()
      end)

      monitor
      |> Monitor.changeset(%{scope_source_id: scope_source.id})
      |> repo().update!()

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

  defp demo_data_sources(base_url) do
    json_mappings = %{
      "program_name" => "program.name",
      "credential" => "program.credential",
      "duration" => "program.duration"
    }

    html_mappings = %{
      "program_name" => "[data-field=program-name]",
      "credential" => "[data-field=credential]",
      "duration" => "[data-field=duration]"
    }

    [
      %{
        key: "source",
        name: "Authoritative program API",
        role: :source,
        format: :json,
        fetch_strategy: :fetch_entity,
        url: base_url <> "/authority/programs/:id",
        mappings: json_mappings
      },
      %{
        key: "delivery",
        name: "Delivery API",
        role: :target,
        format: :json,
        fetch_strategy: :fetch_entity,
        url: base_url <> "/delivery/programs/:id",
        mappings: json_mappings
      },
      %{
        key: "website",
        name: "Public program page",
        role: :target,
        format: :html,
        fetch_strategy: :fetch_entity,
        url: base_url <> "/programs/:id",
        mappings: html_mappings
      },
      %{
        key: "search",
        name: "Program search",
        role: :target,
        format: :html,
        fetch_strategy: :fetch_entity,
        url: base_url <> "/search/programs/:id",
        mappings: html_mappings
      }
    ]
  end

  # ---------------------------------------------------------------------------
  # Private query helpers
  # ---------------------------------------------------------------------------

  defp scoped_issue(instance_id, issue_id) do
    Issue
    |> join(:inner, [i], m in Monitor, on: m.id == i.monitor_id)
    |> where(
      [i, m],
      i.id == ^issue_id and m.application_instance_id == ^instance_id
    )
    |> repo().one()
  end

  defp scoped_source(instance_id, source_id) do
    Source
    |> join(:inner, [s], m in Monitor, on: m.id == s.monitor_id)
    |> where([s, m], s.id == ^source_id and m.application_instance_id == ^instance_id)
    |> repo().one()
  end

  defp scoped_fact(instance_id, fact_id) do
    Fact
    |> join(:inner, [f], m in Monitor, on: m.id == f.monitor_id)
    |> where([f, m], f.id == ^fact_id and m.application_instance_id == ^instance_id)
    |> repo().one()
  end

  defp scoped_window(instance_id, window_id) do
    ScheduleWindow
    |> join(:inner, [w], m in Monitor, on: m.id == w.monitor_id)
    |> where([w, m], w.id == ^window_id and m.application_instance_id == ^instance_id)
    |> repo().one()
  end

  defp sorted_sources_query, do: from(s in Source, order_by: [asc: s.sort_order])

  defp normalize_source_attrs(attrs) do
    case Map.get(attrs, "mappings") do
      s when is_binary(s) ->
        case Jason.decode(s) do
          {:ok, map} when is_map(map) -> Map.put(attrs, "mappings", map)
          _ -> attrs
        end

      _ ->
        attrs
    end
  end

  defp issue_details(monitors, issues) do
    source_ids =
      monitors
      |> Enum.flat_map(& &1.sources)
      |> Enum.filter(&(&1.role == :source))
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
          fact_ids = Enum.map(observations, & &1.fact_id)
          source_ids = Map.values(source_ids)

          Observation
          |> where(
            [o],
            o.run_id in ^run_ids and o.fact_id in ^fact_ids and
              o.source_id in ^source_ids
          )
          |> preload(:evidence)
          |> repo().all()
      end
      |> Map.new(&{{&1.run_id, &1.fact_id, &1.entity_id}, &1})

    Map.new(issues, fn issue ->
      current = issue.current_observation

      authority =
        current &&
          authority_observations[{current.run_id, current.fact_id, current.entity_id}]


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
          {run_id, Map.new(obs, &{{&1.source_id, &1.fact_id}, &1})}
        end)
      end

    Map.new(monitors, fn monitor ->
      run = last_runs[monitor.id]
      cells = if run, do: Map.get(cells_by_run, run.id, %{}), else: %{}

      sources =
        Enum.sort_by(monitor.sources, fn s ->
          {if(s.role == :source, do: 0, else: 1), s.name}
        end)

      facts = Enum.sort_by(monitor.facts, & &1.name)
      authority_id = Enum.find_value(sources, fn s -> if s.role == :source, do: s.id end)

      {monitor.id,
       %{run: run, sources: sources, facts: facts, cells: cells, authority_id: authority_id}}
    end)
  end

  defp latest_summaries([]), do: %{}

  defp latest_summaries(monitors) do
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

    Map.new(monitors, fn monitor ->
      run = last_runs[monitor.id]

      {monitor.id,
       %{
         run: run,
         entity_count: run && length(run.summary["entity_ids"] || []),
         states: run && run.summary["states"] || %{},
         open_issues: run && run.summary["open_issues"] || 0
       }}
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
