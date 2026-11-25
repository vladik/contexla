defmodule Contexla.Tools.Bundled.Test.ExtractionTest do
  use ExUnit.Case, async: true

  alias Contexla.Tools.Bundled.{ExtractHtmlValues, ExtractJsonValues}

  test "extracts named values from JSON paths" do
    assert {:ok, %{"values" => values}} =
             ExtractJsonValues.execute(
               %{
                 "document" => %{
                   "program" => %{"name" => "Nursing", "credential" => "Diploma"}
                 },
                 "mappings" => %{
                   "program_name" => "program.name",
                   "credential" => "$.program.credential",
                   "duration" => "program.duration"
                 }
               },
               %{}
             )

    assert values == %{
             "program_name" => "Nursing",
             "credential" => "Diploma",
             "duration" => nil
           }
  end

  test "extracts and normalizes text from CSS selectors" do
    assert {:ok, %{"values" => values}} =
             ExtractHtmlValues.execute(
               %{
                 "html" => """
                 <article>
                   <h1 class="program-name"> Practical   Nursing </h1>
                   <span data-field="credential">Ontario College Diploma</span>
                 </article>
                 """,
                 "mappings" => %{
                   "program_name" => ".program-name",
                   "credential" => "[data-field=credential]",
                   "duration" => "[data-field=duration]"
                 }
               },
               %{}
             )

    assert values == %{
             "program_name" => "Practical Nursing",
             "credential" => "Ontario College Diploma",
             "duration" => nil
           }
  end
end
