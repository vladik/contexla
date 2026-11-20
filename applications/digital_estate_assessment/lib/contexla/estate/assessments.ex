defmodule Contexla.Estate.Assessments do
  @moduledoc "Application-owned services for Digital Estate Assessment Runs."

  import Ecto.Query, warn: false
  alias Contexla.ApplicationSDK.{Instance, Runtime}

  alias Contexla.Estate.{
    AssessmentRun,
    EvidenceItem,
    Finding,
    InventoryItem,
    Relationship,
    ReviewDecision,
    Snapshot,
    SnapshotComparison
  }

  alias Contexla.Estate.Workers.AssessmentWorker

  @application_id "com.contexla.application.digital-estate-assessment"
  @rule_set_version "1"

  def start_run(%Instance{} = instance, artifact_id) do
    with :ok <- ensure_assessment_instance(instance),
         {:ok, artifact} <- platform(:get_artifact, [instance.actor_id, artifact_id]),
         :ok <- ensure_artifact_belongs_to_instance(artifact, instance),
         adapter_id when is_binary(adapter_id) <- artifact.metadata["adapter_id"],
         {:ok, {integration, adapter}} <- platform(:fetch_adapter, [adapter_id]),
         true <- function_exported?(adapter.module, :normalize_source, 2) do
      repo().transaction(fn ->
        run =
          %AssessmentRun{}
          |> AssessmentRun.create_changeset(%{
            application_instance_id: instance.id,
            source_artifact_id: artifact.id,
            initiated_by_user_id: instance.actor_id,
            status: :queued,
            adapter_id: adapter.id,
            adapter_version: integration.version,
            rule_set_version: @rule_set_version
          })
          |> repo().insert!()

        {:ok, _job} = platform(:enqueue, [AssessmentWorker, %{"assessment_run_id" => run.id}])
        run
      end)
    else
      false -> {:error, :adapter_cannot_normalize}
      {:error, :not_found} -> {:error, :adapter_not_installed}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :artifact_adapter_missing}
    end
  end

  def list_runs(%Instance{} = instance) do
    AssessmentRun
    |> where([run], run.application_instance_id == ^instance.id)
    |> order_by([run], desc: run.inserted_at)
    |> repo().all()
  end

  def results(%Instance{} = instance, run_id) do
    run = run_for_instance!(instance, run_id)
    snapshot = repo().get_by(Snapshot, assessment_run_id: run.id)

    %{
      run: run,
      snapshot: snapshot,
      comparison: snapshot && repo().get_by(SnapshotComparison, current_snapshot_id: snapshot.id),
      evidence_items: list_by_run(EvidenceItem, run.id),
      inventory_items: list_inventory(snapshot),
      relationships: list_relationships(snapshot),
      findings:
        Finding
        |> where([finding], finding.assessment_run_id == ^run.id)
        |> order_by([finding], desc: finding.severity, asc: finding.summary)
        |> repo().all(),
      review_decisions:
        ReviewDecision
        |> join(:inner, [decision], finding in Finding, on: decision.finding_id == finding.id)
        |> where([_decision, finding], finding.assessment_run_id == ^run.id)
        |> order_by([decision], desc: decision.inserted_at)
        |> repo().all()
    }
  end

  def review_finding(%Instance{} = instance, finding_id, to_status, rationale) do
    finding = repo().get!(Finding, finding_id)
    _run = run_for_instance!(instance, finding.assessment_run_id)

    repo().transaction(fn ->
      %ReviewDecision{}
      |> ReviewDecision.changeset(%{
        finding_id: finding.id,
        reviewed_by_user_id: instance.actor_id,
        from_status: finding.status,
        to_status: to_status,
        rationale: rationale
      })
      |> repo().insert!()

      finding |> Finding.status_changeset(to_status) |> repo().update!()
    end)
  rescue
    error in Ecto.InvalidChangesetError -> {:error, error.changeset}
  end

  def add_expert_finding(%Instance{} = instance, run_id, attrs) do
    run = run_for_instance!(instance, run_id)

    attrs =
      attrs
      |> Map.put("assessment_run_id", run.id)
      |> Map.put("created_by_user_id", instance.actor_id)
      |> Map.put("origin", "expert")
      |> Map.put("status", "open")
      |> empty_to_nil("inventory_item_id")
      |> empty_to_nil("evidence_item_id")

    with :ok <- validate_inventory_reference(run, attrs["inventory_item_id"]),
         :ok <- validate_evidence_reference(run, attrs["evidence_item_id"]) do
      %Finding{} |> Finding.changeset(attrs) |> repo().insert()
    end
  end

  def report(%Instance{} = instance, run_id) do
    result = results(instance, run_id)

    %{
      "schema" => "contexla.digital-estate-assessment.report.v1",
      "assessment" => %{
        "id" => instance.id,
        "name" => instance.name,
        "decision" => instance.config["decision"],
        "scope" => instance.config["scope"]
      },
      "run" => %{
        "id" => result.run.id,
        "status" => to_string(result.run.status),
        "adapter" => %{"id" => result.run.adapter_id, "version" => result.run.adapter_version},
        "rule_set_version" => result.run.rule_set_version,
        "started_at" => result.run.started_at,
        "completed_at" => result.run.completed_at,
        "summary" => result.run.summary
      },
      "snapshot" => snapshot_projection(result.snapshot),
      "summary" => report_summary(result),
      "inventory" => Enum.map(result.inventory_items, &inventory_projection/1),
      "comparison" => comparison_projection(result.comparison),
      "relationships" => Enum.map(result.relationships, &relationship_projection/1),
      "findings" => Enum.map(result.findings, &finding_projection/1),
      "review_decisions" => Enum.map(result.review_decisions, &review_decision_projection/1),
      "evidence" => Enum.map(result.evidence_items, &evidence_projection/1)
    }
  end

  defp run_for_instance!(instance, run_id),
    do: repo().get_by!(AssessmentRun, id: run_id, application_instance_id: instance.id)

  defp ensure_assessment_instance(%Instance{application_id: @application_id}), do: :ok
  defp ensure_assessment_instance(_instance), do: {:error, :wrong_application}

  defp ensure_artifact_belongs_to_instance(artifact, instance) do
    if artifact.application_instance_id == instance.id and artifact.kind == "source_snapshot",
      do: :ok,
      else: {:error, :artifact_not_available_for_instance}
  end

  defp list_by_run(schema, run_id),
    do: repo().all(where(schema, [record], record.assessment_run_id == ^run_id))

  defp list_inventory(nil), do: []

  defp list_inventory(snapshot) do
    InventoryItem
    |> where([item], item.snapshot_id == ^snapshot.id)
    |> order_by([item], asc: item.kind, asc: item.name)
    |> repo().all()
  end

  defp list_relationships(nil), do: []

  defp list_relationships(snapshot),
    do: repo().all(where(Relationship, [item], item.snapshot_id == ^snapshot.id))

  defp inventory_projection(item),
    do:
      item
      |> Map.from_struct()
      |> Map.take([:id, :kind, :external_key, :name, :attributes, :evidence_item_id])
      |> stringify_keys()

  defp relationship_projection(item),
    do:
      item
      |> Map.from_struct()
      |> Map.take([
        :kind,
        :from_inventory_item_id,
        :to_inventory_item_id,
        :evidence_item_id,
        :attributes
      ])
      |> stringify_keys()

  defp finding_projection(finding) do
    %{
      "id" => finding.id,
      "origin" => to_string(finding.origin),
      "created_by_user_id" => finding.created_by_user_id,
      "rule" =>
        if(finding.rule_id, do: %{"id" => finding.rule_id, "version" => finding.rule_version}),
      "category" => finding.category,
      "severity" => to_string(finding.severity),
      "confidence" => to_string(finding.confidence),
      "summary" => finding.summary,
      "explanation" => finding.explanation,
      "recommendation" => finding.recommendation,
      "status" => to_string(finding.status),
      "inventory_item_id" => finding.inventory_item_id,
      "evidence_item_id" => finding.evidence_item_id
    }
  end

  defp evidence_projection(item),
    do:
      item
      |> Map.from_struct()
      |> Map.take([:id, :path, :kind, :media_type, :sha256, :byte_size, :metadata])
      |> stringify_keys()

  defp snapshot_projection(nil), do: nil

  defp snapshot_projection(snapshot) do
    %{
      "target_key" => snapshot.target_key,
      "collected_at" => snapshot.collected_at,
      "adapter" => %{"id" => snapshot.adapter_id, "version" => snapshot.adapter_version},
      "limitations" => snapshot.limitations
    }
  end

  defp report_summary(result) do
    %{
      "inventory_total" => length(result.inventory_items),
      "inventory_by_kind" => frequencies(result.inventory_items, & &1.kind),
      "relationship_total" => length(result.relationships),
      "finding_total" => length(result.findings),
      "findings_by_severity" => frequencies(result.findings, &to_string(&1.severity)),
      "findings_by_status" => frequencies(result.findings, &to_string(&1.status)),
      "findings_by_origin" => frequencies(result.findings, &to_string(&1.origin)),
      "evidence_total" => length(result.evidence_items),
      "review_decision_total" => length(result.review_decisions)
    }
  end

  defp frequencies(items, key_function) do
    items
    |> Enum.frequencies_by(key_function)
    |> Map.new(fn {key, count} -> {to_string(key), count} end)
  end

  defp review_decision_projection(item) do
    %{
      "id" => item.id,
      "finding_id" => item.finding_id,
      "reviewed_by_user_id" => item.reviewed_by_user_id,
      "from_status" => to_string(item.from_status),
      "to_status" => to_string(item.to_status),
      "rationale" => item.rationale,
      "created_at" => item.inserted_at
    }
  end

  defp comparison_projection(nil), do: nil

  defp comparison_projection(comparison) do
    previous = repo().get!(Snapshot, comparison.previous_snapshot_id)

    %{
      "previous_run_id" => previous.assessment_run_id,
      "summary" => comparison.summary,
      "changes" => comparison.changes
    }
  end

  defp validate_inventory_reference(_run, nil), do: :ok

  defp validate_inventory_reference(run, inventory_item_id) do
    query =
      from(item in InventoryItem,
        join: snapshot in Snapshot,
        on: item.snapshot_id == snapshot.id,
        where: item.id == ^inventory_item_id and snapshot.assessment_run_id == ^run.id
      )

    if repo().exists?(query), do: :ok, else: {:error, :inventory_item_not_in_run}
  end

  defp validate_evidence_reference(_run, nil), do: :ok

  defp validate_evidence_reference(run, evidence_item_id) do
    query =
      from(item in EvidenceItem,
        where: item.id == ^evidence_item_id and item.assessment_run_id == ^run.id
      )

    if repo().exists?(query), do: :ok, else: {:error, :evidence_item_not_in_run}
  end

  defp stringify_keys(map), do: Map.new(map, fn {key, value} -> {Atom.to_string(key), value} end)

  defp empty_to_nil(attrs, key),
    do: if(attrs[key] in [nil, ""], do: Map.put(attrs, key, nil), else: attrs)

  defp repo, do: Runtime.service!(:repo)
  defp platform(function, arguments), do: Runtime.call(:platform, function, arguments)
end
