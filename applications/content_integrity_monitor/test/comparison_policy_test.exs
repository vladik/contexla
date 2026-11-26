defmodule Contexla.Applications.ContentIntegrityMonitor.Test.ComparisonPolicyTest do
  use ExUnit.Case, async: true

  alias Contexla.Applications.ContentIntegrityMonitor.ComparisonPolicy

  @now ~U[2026-11-24 01:00:00Z]

  test "normalizes bounded scalar values deterministically" do
    assert ComparisonPolicy.normalize("  Ontario   College Diploma ") ==
             "Ontario College Diploma"

    assert ComparisonPolicy.normalize(2) == "2"
    assert ComparisonPolicy.normalize(nil) == nil
    assert ComparisonPolicy.normalize(%{}) == nil
  end

  test "distinguishes healthy, pending, overdue, and immediate mismatch" do
    assert state(value: "Diploma", authority_value: "Diploma") == :healthy

    assert state(
             value: "Certificate",
             authority_value: "Diploma",
             allowed_delay_seconds: 7_200,
             authority_updated_at: DateTime.add(@now, -3_600, :second)
           ) == :pending

    assert state(
             value: "Certificate",
             authority_value: "Diploma",
             allowed_delay_seconds: 3_600,
             authority_updated_at: DateTime.add(@now, -7_200, :second)
           ) == :overdue

    assert state(value: "Certificate", authority_value: "Diploma") == :mismatch

    assert state(
             value: "Certificate",
             authority_value: "Diploma",
             allowed_delay_seconds: 3_600,
             authority_updated_at: nil
           ) == :pending
  end

  test "distinguishes missing, unavailable, and unknown" do
    assert state(value: nil, required: true) == :missing
    assert state(source_status: :failed) == :unavailable
    assert state(authority_status: :failed) == :unknown
    assert state(authority_value: nil) == :unknown
  end

  defp state(overrides) do
    %{
      source_role: :secondary,
      source_status: :completed,
      required: true,
      value: "Diploma",
      authority_status: :completed,
      authority_value: "Diploma",
      allowed_delay_seconds: 0,
      authority_updated_at: @now,
      now: @now
    }
    |> Map.merge(Map.new(overrides))
    |> ComparisonPolicy.evaluate()
  end
end
