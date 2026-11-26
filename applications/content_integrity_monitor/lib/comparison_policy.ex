defmodule Contexla.Applications.ContentIntegrityMonitor.ComparisonPolicy do
  @moduledoc "Pure deterministic normalization and integrity-state evaluation."

  @spec evaluate(map()) :: atom()
  def evaluate(context) when is_map(context) do
    cond do
      context.source_role == :source and context.source_status == :failed ->
        :unavailable

      context.source_role == :source and context.required and is_nil(context.value) ->
        :missing

      context.source_role == :source ->
        :healthy

      context.source_status == :failed ->
        :unavailable

      context.authority_status == :failed ->
        :unknown

      context.required and is_nil(context.value) ->
        :missing

      is_nil(context.authority_value) ->
        :unknown

      context.value == context.authority_value ->
        :healthy

      true ->
        :mismatch
    end
  end

  @spec normalize(term(), atom()) :: String.t() | nil
  def normalize(value, comparison_type \\ :text)
  def normalize(nil, _comparison_type), do: nil

  def normalize(value, :text) do
    value |> to_string() |> String.replace(~r/\s+/u, " ") |> String.trim()
  end

  def normalize(value, :text_case_insensitive) do
    value |> to_string() |> String.replace(~r/\s+/u, " ") |> String.trim() |> String.downcase()
  end

  def normalize(value, :numeric) do
    str = value |> to_string() |> String.replace(~r/[^0-9.\-]/, "")

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
