defmodule Contexla.Processors.Native.ParseComposer do
  @behaviour Contexla.CapabilitySDK.NativeProcessor

  @impl true
  def execute(%{"content" => content, "content_type" => content_type, "field_mappings" => mappings}, _config) do
    fields =
      Enum.reduce(mappings, %{}, fn mapping, acc ->
        field_id = mapping["field_id"]
        selector = mapping["selector"]
        value = extract(content, content_type, selector)
        Map.put(acc, field_id, value)
      end)

    {:ok, %{"fields" => fields}}
  end

  def execute(_input, _config), do: {:error, :invalid_input}

  defp extract(content, "text/html", selector) do
    case Floki.parse_document(content) do
      {:ok, doc} ->
        doc
        |> Floki.find(selector)
        |> Floki.text()
        |> String.trim()

      _ ->
        nil
    end
  end

  defp extract(content, "text/csv", column_header) do
    [header_line | rows] = String.split(content, "\n", trim: true)
    headers = header_line |> String.split(",") |> Enum.map(&String.trim/1)
    col_index = Enum.find_index(headers, &(&1 == column_header))

    if col_index do
      rows
      |> Enum.map(fn row ->
        row |> String.split(",") |> Enum.at(col_index, "") |> String.trim()
      end)
      |> Enum.reject(&(&1 == ""))
      |> List.first()
    end
  end

  defp extract(content, "text/plain", path) do
    keys = String.split(path, ".")

    Enum.reduce_while(keys, content, fn key, acc ->
      cond do
        is_map(acc) -> {:cont, Map.get(acc, key)}
        is_binary(acc) ->
          case Jason.decode(acc) do
            {:ok, map} -> {:cont, Map.get(map, key)}
            _ -> {:halt, nil}
          end
        true -> {:halt, nil}
      end
    end)
    |> to_string_value()
  end

  defp extract(_content, _content_type, _selector), do: nil

  defp to_string_value(nil), do: nil
  defp to_string_value(value) when is_binary(value), do: value
  defp to_string_value(value), do: to_string(value)
end
