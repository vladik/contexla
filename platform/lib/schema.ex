defmodule Contexla.Platform.Schema do
  @moduledoc "Validates the JSON Schema subset used by Application Operation inputs."

  @spec validate(term(), map()) :: :ok | {:error, map()}
  def validate(value, schema) when is_map(schema), do: validate(value, schema, "$")

  defp validate(value, %{"type" => "object"} = schema, path) when is_map(value) do
    with :ok <- required(value, schema, path),
         :ok <- additional_properties(value, schema, path) do
      schema
      |> Map.get("properties", %{})
      |> Enum.reduce_while(:ok, fn {key, child_schema}, :ok ->
        if Map.has_key?(value, key) do
          case validate(Map.fetch!(value, key), child_schema, path <> "." <> key) do
            :ok -> {:cont, :ok}
            error -> {:halt, error}
          end
        else
          {:cont, :ok}
        end
      end)
    end
  end

  defp validate(value, %{"type" => "array", "items" => item_schema}, path)
       when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {item, index}, :ok ->
      case validate(item, item_schema, path <> "[#{index}]") do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate(value, %{"type" => "string"}, _path) when is_binary(value), do: :ok
  defp validate(value, %{"type" => "integer"}, _path) when is_integer(value), do: :ok
  defp validate(value, %{"type" => "number"}, _path) when is_number(value), do: :ok
  defp validate(value, %{"type" => "boolean"}, _path) when is_boolean(value), do: :ok
  defp validate(nil, %{"type" => "null"}, _path), do: :ok
  defp validate(_value, schema, _path) when map_size(schema) == 0, do: :ok

  defp validate(_value, schema, path),
    do: {:error, %{path: path, expected: schema["type"] || "declared schema"}}

  defp required(value, schema, path) do
    case schema |> Map.get("required", []) |> Enum.reject(&Map.has_key?(value, &1)) do
      [] -> :ok
      keys -> {:error, %{path: path, missing: keys}}
    end
  end

  defp additional_properties(value, %{"additionalProperties" => false} = schema, path) do
    allowed = schema |> Map.get("properties", %{}) |> Map.keys() |> MapSet.new()
    extra = value |> Map.keys() |> MapSet.new() |> MapSet.difference(allowed) |> Enum.sort()
    if extra == [], do: :ok, else: {:error, %{path: path, unexpected: extra}}
  end

  defp additional_properties(_value, _schema, _path), do: :ok

  @doc "Projects declared fields for audit storage and redacts schema-marked sensitive values."
  def audit_projection(value, schema) when is_map(schema), do: project_for_audit(value, schema)

  defp project_for_audit(_value, %{"sensitive" => true}), do: "[REDACTED]"

  defp project_for_audit(value, %{"type" => "object"} = schema) when is_map(value) do
    properties = Map.get(schema, "properties", %{})

    declared =
      Enum.reduce(properties, %{}, fn {key, child_schema}, projected ->
        if Map.has_key?(value, key) do
          Map.put(projected, key, project_for_audit(Map.fetch!(value, key), child_schema))
        else
          projected
        end
      end)

    case Map.get(schema, "additionalProperties", true) do
      false ->
        declared

      additional_schema when is_map(additional_schema) ->
        project_additional(value, properties, declared, additional_schema)

      _allowed ->
        project_additional(value, properties, declared, %{})
    end
  end

  defp project_for_audit(value, %{"type" => "array", "items" => item_schema})
       when is_list(value),
       do: Enum.map(value, &project_for_audit(&1, item_schema))

  defp project_for_audit(value, _schema), do: value

  defp project_additional(value, properties, projected, schema) do
    Enum.reduce(value, projected, fn {key, child_value}, result ->
      if Map.has_key?(properties, key) do
        result
      else
        Map.put(result, key, project_for_audit(child_value, schema))
      end
    end)
  end
end
