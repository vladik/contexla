defmodule Contexla.Tools.Bundled.ExtractHtmlValues do
  @moduledoc "Extracts named text values from HTML using CSS selectors."

  @behaviour Contexla.Tools.Sdk.NativeTool

  @impl true
  def execute(%{"html" => html, "mappings" => mappings}, _context)
      when is_binary(html) and is_map(mappings) do
    with :ok <- validate_mappings(mappings),
         {:ok, document} <- Floki.parse_document(html) do
      values =
        Map.new(mappings, fn {name, selector} ->
          value =
            document
            |> Floki.find(selector)
            |> List.first()
            |> text()

          {name, value}
        end)

      {:ok, %{"values" => values}}
    else
      {:error, _reason} -> {:error, :invalid_html_document}
    end
  end

  def execute(_input, _context), do: {:error, :invalid_html_extraction_input}

  defp validate_mappings(mappings) do
    if Enum.all?(mappings, fn {name, selector} -> non_empty?(name) and non_empty?(selector) end),
      do: :ok,
      else: {:error, :invalid_html_mapping}
  end

  defp text(nil), do: nil

  defp text(node) do
    node
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
