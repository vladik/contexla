defmodule Contexla.EstateTest do
  use ExUnit.Case

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
end
