defmodule Contexla.Processors.NativeTest do
  use ExUnit.Case, async: true

  alias Contexla.Processors.Native
  alias Contexla.Processors.Native.ParseComposer
  alias Contexla.CapabilitySDK
  alias Contexla.CapabilitySDK.Processor

  describe "processors/0" do
    test "returns a non-empty list" do
      procs = Native.processors()
      assert is_list(procs)
      assert length(procs) > 0
    end

    test "all processors are valid" do
      for proc <- Native.processors() do
        assert :ok = Processor.validate(proc)
      end
    end

    test "package validates successfully" do
      assert {:ok, _} = CapabilitySDK.validate_processor_package(Native)
    end

    test "includes default parse-composer processor" do
      proc = Enum.find(Native.processors(), &(&1.capability_id == "contexla.parse-composer"))
      assert proc != nil
      assert proc.default == true
    end
  end

  describe "ParseComposer.execute/2" do
    test "extracts field from HTML via CSS selector" do
      html = "<html><body><h1 class=\"title\">Hello World</h1></body></html>"

      input = %{
        "content" => html,
        "content_type" => "text/html",
        "field_mappings" => [%{"field_id" => "title", "selector" => "h1.title"}]
      }

      assert {:ok, %{"fields" => %{"title" => "Hello World"}}} = ParseComposer.execute(input, %{})
    end

    test "extracts column from CSV" do
      csv = "ProductName,Price,SKU\nWidget A,9.99,WA001\n"

      input = %{
        "content" => csv,
        "content_type" => "text/csv",
        "field_mappings" => [%{"field_id" => "product", "selector" => "ProductName"}]
      }

      assert {:ok, %{"fields" => %{"product" => "Widget A"}}} = ParseComposer.execute(input, %{})
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_input} = ParseComposer.execute(%{}, %{})
    end
  end
end
