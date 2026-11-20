defmodule Contexla.EstateTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias Contexla.ApplicationSDK.Instance

  test "exposes the bundled Digital Estate Assessment definition" do
    assert {:ok, definition} = Contexla.ApplicationSDK.validate_module(Contexla.Estate)
    assert definition.id == "com.contexla.application.digital-estate-assessment"
    assert definition.otp_application == :contexla_estate
    assert "contexla.estate.source.v1" in definition.required_adapter_contracts

    run = Enum.find(definition.operations, &(&1.id == "assessment.run"))
    assert [requirement] = run.required_capabilities
    assert requirement.capability_id == "com.contexla.dependencies.parse-composer"
  end

  test "requires a decision and scope for an Instance" do
    config = %{"decision" => "Plan the Drupal modernization", "scope" => %{}}

    assert {:ok, ^config} = Contexla.Estate.validate_instance_config(config)
    assert {:error, {:invalid_config, _reason}} = Contexla.Estate.validate_instance_config(%{})
  end

  test "produces deterministic evidence-gap and custom-module findings" do
    normalized = %{
      evidence: [
        %{path: "sources/drupal-status.json"},
        %{path: "sources/modules.json"}
      ],
      resources: [
        %{
          kind: "cms",
          external_key: "college",
          name: "College",
          attributes: %{},
          evidence_path: "sources/drupal-status.json"
        },
        %{
          kind: "module",
          external_key: "college_sis",
          name: "College SIS",
          attributes: %{"origin" => "custom"},
          evidence_path: "sources/modules.json"
        }
      ]
    }

    findings = Contexla.Estate.Rules.evaluate(normalized)

    assert Enum.any?(findings, &(&1.rule_id == "drupal.version.unknown"))

    assert Enum.any?(
             findings,
             &(&1.rule_id == "custom_module.maintenance_metadata_missing")
           )

    assert Enum.any?(findings, &(&1.rule_id == "evidence.missing.themes.json"))
  end

  test "renders a buyer-reviewable evidence-backed report" do
    instance = %Instance{
      id: "assessment-instance",
      application_id: "com.contexla.application.digital-estate-assessment",
      application_version: "0.1.0",
      name: "College Drupal Estate",
      config: %{},
      actor_id: "user-1"
    }

    report = %{
      "schema" => "contexla.digital-estate-assessment.report.v1",
      "assessment" => %{
        "name" => "College Drupal Estate",
        "decision" => "Decide whether to modernize the Drupal estate",
        "scope" => %{"cms" => "drupal", "environment" => "production"}
      },
      "run" => %{
        "id" => "run-1",
        "status" => "succeeded",
        "completed_at" => ~U[2026-11-19 20:00:00Z],
        "rule_set_version" => "1",
        "adapter" => %{"id" => "drupal.assessment.snapshot.v1", "version" => "0.1.0"}
      },
      "snapshot" => %{
        "target_key" => "college-public-web",
        "collected_at" => ~U[2026-11-19 19:00:00Z],
        "limitations" => ["Configuration export was not supplied."]
      },
      "summary" => %{
        "inventory_total" => 1,
        "relationship_total" => 0,
        "finding_total" => 1,
        "findings_by_severity" => %{"medium" => 1},
        "evidence_total" => 1
      },
      "comparison" => nil,
      "inventory" => [
        %{
          "id" => "item-1",
          "kind" => "module",
          "name" => "College integration",
          "external_key" => "college_integration",
          "evidence_item_id" => "evidence-1"
        }
      ],
      "findings" => [
        %{
          "id" => "finding-1",
          "origin" => "deterministic",
          "severity" => "medium",
          "confidence" => "high",
          "status" => "open",
          "summary" => "Custom module ownership is unknown",
          "explanation" => "The supplied evidence does not declare an owner.",
          "recommendation" => "Confirm an accountable owner.",
          "rule" => %{"id" => "custom_module.owner_missing", "version" => "1"},
          "created_by_user_id" => nil,
          "inventory_item_id" => "item-1",
          "evidence_item_id" => "evidence-1"
        }
      ],
      "review_decisions" => [],
      "evidence" => [
        %{
          "id" => "evidence-1",
          "path" => "sources/modules.json",
          "sha256" => String.duplicate("a", 64),
          "byte_size" => 128,
          "media_type" => "application/json"
        }
      ]
    }

    html =
      render_component(&Contexla.EstateWeb.ReportLive.render/1, %{
        instance: instance,
        report: report
      })

    assert html =~ "Decision and scope"
    assert html =~ "Collection limitations"
    assert html =~ "Estate inventory"
    assert html =~ "Custom module ownership is unknown"
    assert html =~ "Rule custom_module.owner_missing v1"
    assert html =~ "Evidence appendix"
  end
end
