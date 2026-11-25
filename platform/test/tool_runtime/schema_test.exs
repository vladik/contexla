defmodule Contexla.Platform.Test.ToolRuntime.SchemaTest do
  use ExUnit.Case, async: true

  alias Contexla.Platform.ToolRuntime.Schema

  test "retains allowed dynamic output properties while redacting declared sensitive fields" do
    schema = %{
      "type" => "object",
      "properties" => %{
        "document" => %{"type" => "string", "sensitive" => true},
        "values" => %{"type" => "object"}
      }
    }

    value = %{
      "document" => "private source body",
      "values" => %{"credential" => "Diploma", "duration" => "2 years"}
    }

    assert Schema.audit_projection(value, schema) == %{
             "document" => "[REDACTED]",
             "values" => %{"credential" => "Diploma", "duration" => "2 years"}
           }
  end

  test "drops undeclared properties when the schema forbids them" do
    schema = %{
      "type" => "object",
      "additionalProperties" => false,
      "properties" => %{"value" => %{"type" => "string"}}
    }

    assert Schema.audit_projection(%{"value" => "kept", "other" => "dropped"}, schema) == %{
             "value" => "kept"
           }
  end
end
