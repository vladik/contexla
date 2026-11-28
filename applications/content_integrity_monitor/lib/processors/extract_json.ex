defmodule Contexla.Applications.ContentIntegrityMonitor.Processors.ExtractJson do
  @spec run(map(), map()) :: {:ok, map()} | {:error, term()}
  def run(document, mappings) when is_map(document) and is_map(mappings) do
    with :ok <- validate_mappings(mappings) do
      values = Map.new(mappings, fn {name, path} -> {name, value_at(document, path)} end)
      {:ok, values}
    end
  end

  def run(_document, _mappings), do: {:error, :invalid_json_extraction_input}

  defp validate_mappings(mappings) do
    if Enum.all?(mappings, fn {k, v} -> is_binary(k) and is_binary(v) end) do
      :ok
    else
      {:error, :invalid_mappings}
    end
  end

  defp value_at(document, path) do
    path
    |> String.split(".", trim: true)
    |> Enum.reduce(document, fn
      key, map when is_map(map) -> Map.get(map, key)
      _key, _other -> nil
    end)
  end
end
