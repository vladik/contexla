defmodule Contexla.Estate.Executor do
  @moduledoc "Executes and persists one evidence-backed Assessment Run."

  import Ecto.Query, warn: false

  alias Contexla.ApplicationSDK.Runtime

  alias Contexla.Estate.{
    AssessmentRun,
    EvidenceItem,
    Finding,
    InventoryItem,
    Relationship,
    Rules,
    Snapshot,
    SnapshotComparison
  }

  def perform(run_id) do
    case repo().get(AssessmentRun, run_id) do
      nil -> {:discard, :assessment_run_not_found}
      %AssessmentRun{status: :succeeded} -> :ok
      run -> execute_safely(run)
    end
  end

  defp execute_safely(run) do
    execute(run)
  rescue
    error -> fail(run, {:exception, Exception.message(error)})
  catch
    kind, reason -> fail(run, {kind, reason})
  end

  defp execute(run) do
    run = mark_running(run)
    {:ok, artifact} = Runtime.get_artifact(run.initiated_by_user_id, run.source_artifact_id)

    with {:ok, {_integration, adapter}} <- Runtime.fetch_adapter(run.adapter_id),
         path <- Runtime.artifact_path(artifact),
         {:ok, normalized} <- adapter.module.normalize_source(path, []),
         {:ok, normalized} <-
           add_composer_dependencies(
             normalized,
             run.initiated_by_user_id,
             run.application_instance_id
           ),
         findings = Rules.evaluate(normalized),
         {:ok, completed} <- persist_result(run, artifact, normalized, findings) do
      _ = completed
      :ok
    else
      {:error, reason} -> fail(run, reason)
    end
  end

  defp mark_running(run) do
    run
    |> AssessmentRun.status_changeset(%{
      status: :running,
      started_at: run.started_at || DateTime.utc_now(:second),
      error: nil
    })
    |> repo().update!()
  end

  defp add_composer_dependencies(normalized, actor_id, instance_id) do
    composer_json = document(normalized.documents, "composer.json")
    composer_lock = document(normalized.documents, "composer.lock")

    if is_map(composer_json) and is_map(composer_lock) do
      case Runtime.invoke_capability(
             actor_id,
             instance_id,
             "com.contexla.dependencies.parse-composer",
             "1",
             %{"composer_json" => composer_json, "composer_lock" => composer_lock}
           ) do
        {:ok, %{"dependencies" => dependencies}, _invocation} ->
          root = Enum.find(normalized.resources, &(&1.kind == "cms"))
          lock_path = find_path(normalized.documents, "composer.lock")

          resources =
            Enum.map(dependencies, fn dependency ->
              %{
                kind: "dependency",
                external_key: dependency["name"],
                name: dependency["name"],
                attributes: dependency,
                evidence_path: lock_path
              }
            end)

          relationships =
            Enum.map(resources, fn resource ->
              %{
                from: {root.kind, root.external_key},
                to: {resource.kind, resource.external_key},
                kind: "depends_on",
                attributes: %{},
                evidence_path: lock_path
              }
            end)

          {:ok,
           normalized
           |> Map.update!(:resources, &(&1 ++ resources))
           |> Map.update!(:relationships, &(&1 ++ relationships))}

        {:error, reason} ->
          {:error, {:composer_capability_failed, reason}}
      end
    else
      {:ok, normalized}
    end
  end

  defp persist_result(run, artifact, normalized, findings) do
    repo().transaction(fn ->
      evidence = persist_evidence(run, artifact, normalized.evidence)
      snapshot = persist_snapshot(run, normalized)
      inventory = persist_inventory(snapshot, normalized.resources, evidence)
      persist_relationships(snapshot, normalized.relationships, inventory, evidence)
      persist_findings(run, findings, inventory, evidence)
      comparison = persist_comparison(run, snapshot, inventory)

      summary = %{
        "evidence_items" => map_size(evidence),
        "inventory_items" => map_size(inventory),
        "relationships" => length(normalized.relationships),
        "findings" => length(findings),
        "changes" => comparison && comparison.summary
      }

      run
      |> AssessmentRun.status_changeset(%{
        status: :succeeded,
        summary: summary,
        completed_at: DateTime.utc_now(:second),
        error: nil
      })
      |> repo().update!()
    end)
  end

  defp persist_evidence(run, artifact, evidence) do
    Map.new(evidence, fn item ->
      record =
        %EvidenceItem{}
        |> EvidenceItem.changeset(
          item
          |> Map.put(:assessment_run_id, run.id)
          |> Map.put(:artifact_id, artifact.id)
        )
        |> repo().insert!()

      {item.path, record}
    end)
  end

  defp persist_snapshot(run, normalized) do
    %Snapshot{}
    |> Snapshot.changeset(%{
      assessment_run_id: run.id,
      target_key: normalized.target_key,
      adapter_id: normalized.adapter_id,
      adapter_version: normalized.adapter_version,
      collected_at: normalized.collected_at,
      limitations: normalized.limitations
    })
    |> repo().insert!()
  end

  defp persist_inventory(snapshot, resources, evidence) do
    Map.new(resources, fn resource ->
      evidence_item = evidence[resource.evidence_path]

      record =
        %InventoryItem{}
        |> InventoryItem.changeset(%{
          snapshot_id: snapshot.id,
          evidence_item_id: evidence_item && evidence_item.id,
          kind: resource.kind,
          external_key: resource.external_key,
          name: resource.name,
          attributes: resource.attributes
        })
        |> repo().insert!()

      {{resource.kind, resource.external_key}, record}
    end)
  end

  defp persist_relationships(snapshot, relationships, inventory, evidence) do
    Enum.each(relationships, fn relationship ->
      with %{id: from_id} <- inventory[relationship.from],
           %{id: to_id} <- inventory[relationship.to] do
        evidence_item = evidence[relationship.evidence_path]

        %Relationship{}
        |> Relationship.changeset(%{
          snapshot_id: snapshot.id,
          from_inventory_item_id: from_id,
          to_inventory_item_id: to_id,
          evidence_item_id: evidence_item && evidence_item.id,
          kind: relationship.kind,
          attributes: relationship.attributes
        })
        |> repo().insert!()
      else
        _missing_endpoint -> :ok
      end
    end)
  end

  defp persist_findings(run, findings, inventory, evidence) do
    Enum.each(findings, fn finding ->
      inventory_item = inventory[finding[:resource_key]]
      evidence_item = evidence[finding[:evidence_path]]

      %Finding{}
      |> Finding.changeset(
        finding
        |> Map.put(:assessment_run_id, run.id)
        |> Map.put(:inventory_item_id, inventory_item && inventory_item.id)
        |> Map.put(:evidence_item_id, evidence_item && evidence_item.id)
      )
      |> repo().insert!()
    end)
  end

  defp persist_comparison(run, snapshot, current_inventory) do
    previous =
      from(previous_run in AssessmentRun,
        join: previous_snapshot in Snapshot,
        on: previous_snapshot.assessment_run_id == previous_run.id,
        where:
          previous_run.application_instance_id == ^run.application_instance_id and
            previous_run.status == :succeeded and
            previous_snapshot.target_key == ^snapshot.target_key,
        order_by: [desc: previous_run.completed_at, desc: previous_run.inserted_at],
        limit: 1,
        select: previous_snapshot
      )
      |> repo().one()

    if previous do
      previous_inventory =
        InventoryItem
        |> where([item], item.snapshot_id == ^previous.id)
        |> repo().all()
        |> Map.new(&{{&1.kind, &1.external_key}, &1})

      changes = compare_inventory(previous_inventory, current_inventory)
      summary = Map.new(changes, fn {kind, items} -> {kind, length(items)} end)

      %SnapshotComparison{}
      |> SnapshotComparison.changeset(%{
        previous_snapshot_id: previous.id,
        current_snapshot_id: snapshot.id,
        summary: summary,
        changes: changes
      })
      |> repo().insert!()
    end
  end

  defp compare_inventory(previous, current) do
    previous_keys = MapSet.new(Map.keys(previous))
    current_keys = MapSet.new(Map.keys(current))

    added =
      current_keys
      |> MapSet.difference(previous_keys)
      |> Enum.map(&comparison_item(current[&1]))
      |> Enum.sort_by(&{&1["kind"], &1["external_key"]})

    removed =
      previous_keys
      |> MapSet.difference(current_keys)
      |> Enum.map(&comparison_item(previous[&1]))
      |> Enum.sort_by(&{&1["kind"], &1["external_key"]})

    changed =
      previous_keys
      |> MapSet.intersection(current_keys)
      |> Enum.flat_map(fn key ->
        before = comparison_value(previous[key])
        after_value = comparison_value(current[key])

        if before == after_value do
          []
        else
          [
            %{
              "kind" => elem(key, 0),
              "external_key" => elem(key, 1),
              "before" => before,
              "after" => after_value
            }
          ]
        end
      end)
      |> Enum.sort_by(&{&1["kind"], &1["external_key"]})

    %{"added" => added, "removed" => removed, "changed" => changed}
  end

  defp comparison_item(item) do
    %{
      "kind" => item.kind,
      "external_key" => item.external_key,
      "name" => item.name,
      "attributes" => item.attributes
    }
  end

  defp comparison_value(item), do: %{"name" => item.name, "attributes" => item.attributes}

  defp fail(run, reason) do
    run
    |> AssessmentRun.status_changeset(%{
      status: :failed,
      error: %{"reason" => inspect(reason)},
      completed_at: DateTime.utc_now(:second)
    })
    |> repo().update()

    {:error, reason}
  end

  defp document(documents, basename) do
    case find_path(documents, basename) do
      nil -> nil
      path -> documents[path]
    end
  end

  defp find_path(documents, basename),
    do: Enum.find(Map.keys(documents), &(Path.basename(&1) == basename))

  defp repo, do: Runtime.repo!()
end
