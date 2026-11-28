defmodule Contexla.Applications.ContentIntegrityMonitor.Processors.ExtractHtml do
  @spec run(binary(), map()) :: {:ok, map()} | {:error, term()}
  def run(html, mappings) when is_binary(html) and is_map(mappings) do
    with :ok <- validate_mappings(mappings),
         {:ok, document} <- Floki.parse_document(html) do
      values =
        Map.new(mappings, fn {name, selector} ->
          text =
            document
            |> Floki.find(selector)
            |> List.first()
            |> text()

          {name, text}
        end)

      {:ok, values}
    else
      {:error, _reason} -> {:error, :invalid_html_document}
    end
  end

  def run(_html, _mappings), do: {:error, :invalid_html_extraction_input}

  defp validate_mappings(mappings) do
    if Enum.all?(mappings, fn {k, v} -> is_binary(k) and is_binary(v) end) do
      :ok
    else
      {:error, :invalid_mappings}
    end
  end

  defp text(nil), do: nil
  defp text(node), do: node |> Floki.text() |> String.trim()
end
