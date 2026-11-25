defmodule Contexla.Applications.ContentIntegrityMonitor.ComparisonPolicy do
  @moduledoc "Pure deterministic normalization and integrity-state evaluation."

  @spec evaluate(map()) :: atom()
  def evaluate(context) when is_map(context) do
    authority_updated_at = context.authority_updated_at || context.now

    cond do
      context.source_role == :authority and context.source_status == :failed ->
        :unavailable

      context.source_role == :authority and context.required and is_nil(context.value) ->
        :missing

      context.source_role == :authority ->
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

      inside_delay?(context.allowed_delay_seconds, authority_updated_at, context.now) ->
        :pending

      context.allowed_delay_seconds > 0 ->
        :overdue

      true ->
        :mismatch
    end
  end

  def normalize(nil), do: nil

  def normalize(value) when is_binary(value),
    do: value |> String.replace(~r/\s+/u, " ") |> String.trim()

  def normalize(value) when is_number(value) or is_boolean(value), do: to_string(value)
  def normalize(_value), do: nil

  def source_updated_at(nil), do: nil

  def source_updated_at(evidence) do
    case evidence.values["_updated_at"] do
      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> datetime
          _error -> nil
        end

      _value ->
        nil
    end
  end

  defp inside_delay?(delay, %DateTime{} = updated_at, %DateTime{} = now) when delay > 0,
    do: DateTime.diff(now, updated_at, :second) < delay

  defp inside_delay?(_delay, _updated_at, _now), do: false
end
