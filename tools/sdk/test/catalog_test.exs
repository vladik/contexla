defmodule Contexla.Tools.Sdk.Test.CatalogTest do
  use ExUnit.Case, async: true

  alias Contexla.Tools.Sdk.Tool

  defmodule Package do
    @behaviour Contexla.Tools.Sdk.Package

    @impl true
    def tools do
      [
        %Tool{
          id: "test.echo",
          version: "1.0.0",
          name: "Echo",
          purpose: "Return its input.",
          runtime: :native,
          entrypoint: __MODULE__,
          input_schema: %{"type" => "object"},
          output_schema: %{"type" => "object"}
        }
      ]
    end
  end

  test "validates a Tool package" do
    assert {:ok, [%Tool{id: "test.echo", version: "1.0.0"}]} =
             Contexla.Tools.Sdk.Catalog.validate_package(Package)
  end
end
