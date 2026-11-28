defmodule Contexla.Tools.Bundled.ExtractJsonValues do
  @moduledoc "Extracts named values from a JSON object using bounded dotted paths."

  @behaviour Contexla.Tools.Sdk.NativeTool

  @impl true
  def execute(%{"document" => document, "mappings" => mappings}, _context)
      when is_map(document) and is_map(mappings) do
    with :ok <- validate_mappings(mappings) do
      values = Map.new(mappings, fn {name, path} -> {name, value_at(document, path)} end)
      {:ok, %{"values" => values}}
    end
  end

  def execute(_input, _context), do: {:error, :invalid_json_extraction_input}

  defp validate_mappings(mappings) do
    if Enum.all?(mappings, fn {name, path} -> non_empty?(name) and non_empty?(path) end),
      do: :ok,
      else: {:error, :invalid_json_mapping}
  end

  defp value_at(document, path) do
    path
    |> String.trim_leading("$.")
    |> String.split(".", trim: true)
    |> Enum.reduce_while(document, fn segment, current ->
      case current do
        map when is_map(map) ->
          if Map.has_key?(map, segment),
            do: {:cont, Map.fetch!(map, segment)},
            else: {:halt, nil}

        _other ->
          {:halt, nil}
      end
    end)
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
