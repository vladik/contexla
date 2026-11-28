defmodule Contexla.Applications.ContentIntegrityMonitor.Test.PackageTest do
  use ExUnit.Case, async: true

  test "declares a valid independent Application definition" do
    definition = Contexla.Applications.ContentIntegrityMonitor.Package.definition()

    assert definition.id == "com.contexla.application.content-integrity-monitor"
    assert definition.database_schema == "contexla_integrity"
    assert :ok = Contexla.Applications.Sdk.Definition.validate(definition)

    assert Enum.map(definition.operations, & &1.id) == [
             "integrity.demo_setup",
             "integrity.run",
             "integrity.issue.acknowledge",
             "integrity.issue.resolve"
           ]
  end
end
