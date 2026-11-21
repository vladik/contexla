defmodule Contexla.CapabilityRuntime.SchemaTest do
  use ExUnit.Case, async: true

  alias Contexla.CapabilityRuntime.Schema

  @schema %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "credential"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "credential" => %{"type" => "string", "sensitive" => true}
    }
  }

  test "rejects undeclared object properties" do
    assert {:error, %{path: "$", unexpected: ["extra"]}} =
             Schema.validate(
               %{"name" => "Source", "credential" => "secret", "extra" => true},
               @schema
             )
  end

  test "projects only declared fields and redacts sensitive values for audit" do
    assert Schema.audit_projection(
             %{"name" => "Source", "credential" => "secret", "ignored" => "value"},
             @schema
           ) == %{"name" => "Source", "credential" => "[REDACTED]"}
  end
end
