defmodule Contexla.Applications.ContentIntegrityMonitor.ComparisonPolicy do
  @moduledoc "Pure deterministic normalization and integrity-state evaluation."

  @spec evaluate(map()) :: atom()
  def evaluate(context) when is_map(context) do
    comparison_type = Map.get(context, :comparison_type, :text)

    cond do
      context.source_role == :source and context.source_status == :failed ->
        :unavailable

      context.source_role == :source ->
        :healthy

      context.source_status == :failed ->
        :unavailable

      comparison_type == :exists ->
        if is_nil(context.value), do: :missing, else: :healthy

      comparison_type == :regex ->
        pattern = Map.get(context, :pattern)

        cond do
          is_nil(context.value) -> :missing
          is_nil(pattern) or pattern == "" -> :healthy
          true ->
            case Regex.compile(pattern) do
              {:ok, re} -> if Regex.match?(re, context.value), do: :healthy, else: :mismatch
              {:error, _} -> :unknown
            end
        end

      context.authority_status == :failed ->
        :unknown

      context.required and is_nil(context.value) ->
        :missing

      is_nil(context.authority_value) ->
        :unknown

      comparison_type == :text_prefix ->
        stripped = (context.value || "") |> String.replace(~r/[\s…\.]+$/u, "") |> String.trim()
        if String.starts_with?(context.authority_value, stripped), do: :healthy, else: :mismatch

      context.value == context.authority_value ->
        :healthy

      true ->
        :mismatch
    end
  end

  @spec normalize(term(), atom()) :: String.t() | nil
  def normalize(value, comparison_type \\ :text)
  def normalize(nil, _comparison_type), do: nil

  def normalize(value, :exists) do
    str = value |> to_string() |> String.trim()
    if str == "", do: nil, else: "1"
  end

  def normalize(value, :text) do
    value |> to_string() |> String.replace(~r/\s+/u, " ") |> String.trim()
  end

  def normalize(value, :text_case_insensitive) do
    value |> to_string() |> String.replace(~r/\s+/u, " ") |> String.trim() |> String.downcase()
  end

  def normalize(value, :text_prefix) do
    value |> to_string() |> String.replace(~r/\s+/u, " ") |> String.trim()
  end

  def normalize(value, :regex) do
    value |> to_string() |> String.replace(~r/\s+/u, " ") |> String.trim()
  end

  def normalize(value, :numeric) do
    str = value |> to_string() |> String.replace(~r/[^0-9.,\-]/, "")

    str =
      cond do
        # Comma as decimal separator: no dot present, comma followed by 1-2 digits at end
        not String.contains?(str, ".") and Regex.match?(~r/,\d{1,2}$/, str) ->
          String.replace(str, ",", ".")

        # Dot is decimal separator: strip thousands commas
        String.contains?(str, ".") ->
          String.replace(str, ",", "")

        # No decimal at all: strip commas (thousands separators)
        true ->
          String.replace(str, ",", "")
      end

    case Float.parse(str) do
      {f, _} -> to_string(f)
      :error -> nil
    end
  end

  def normalize(value, :date) do
    str = value |> to_string() |> String.trim()

    cond do
      match = Regex.run(~r/^(\d{4})-(\d{2})-(\d{2})/, str) ->
        [_, y, m, d] = match
        "#{y}-#{m}-#{d}"

      match = Regex.run(~r/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/, str) ->
        [_, d, m, y] = match
        "#{y}-#{String.pad_leading(m, 2, "0")}-#{String.pad_leading(d, 2, "0")}"

      true ->
        str
    end
  end
end
