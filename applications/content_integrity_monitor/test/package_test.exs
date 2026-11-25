defmodule Contexla.Applications.ContentIntegrityMonitor.Test.PackageTest do
  use ExUnit.Case, async: true

  test "declares a valid independent Application definition" do
    definition = Contexla.Applications.ContentIntegrityMonitor.Package.definition()

    assert definition.id == "com.contexla.application.content-integrity-monitor"
    assert definition.database_schema == "contexla_integrity"
    assert :ok = Contexla.Applications.Sdk.Definition.validate(definition)

    run = Enum.find(definition.operations, &(&1.id == "integrity.run"))

    assert Enum.map(run.required_tools, &{&1.tool_id, &1.version}) == [
             {"com.contexla.extract.json-values", "1.0.0"},
             {"com.contexla.extract.html-values", "1.0.0"}
           ]

    assert Enum.map(definition.operations, & &1.id) == [
             "integrity.demo_setup",
             "integrity.run",
             "integrity.issue.acknowledge",
             "integrity.issue.resolve"
           ]
  end
end
