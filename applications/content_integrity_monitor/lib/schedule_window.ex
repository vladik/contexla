defmodule Contexla.Applications.ContentIntegrityMonitor.ScheduleWindow do
  @moduledoc "An iCal recurrence window during which scheduled runs are suppressed."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "contexla_integrity"

  schema "integrity_schedule_windows" do
    field(:label, :string)
    field(:rrule, :string)
    field(:duration_seconds, :integer)
    belongs_to(:monitor, Contexla.Applications.ContentIntegrityMonitor.Monitor)
    timestamps(type: :utc_datetime)
  end

  def changeset(window, attrs) do
    window
    |> cast(attrs, [:monitor_id, :label, :rrule, :duration_seconds])
    |> validate_required([:monitor_id, :rrule, :duration_seconds])
    |> validate_number(:duration_seconds, greater_than: 0)
  end

  @doc "Returns true when now falls within any active window for the given monitor."
  def any_active?(windows, now \\ DateTime.utc_now()) do
    Enum.any?(windows, &active?(&1, now))
  end

  defp active?(%__MODULE__{rrule: rrule, duration_seconds: duration}, now) do
    earliest = DateTime.add(now, -duration, :second)

    rrule
    |> Cocktail.Schedule.from_i_calendar()
    |> Cocktail.Schedule.occurrences(earliest)
    |> Enum.take_while(&(DateTime.compare(&1, now) != :gt))
    |> Enum.any?(&(DateTime.diff(now, &1, :second) < duration))
  rescue
    _ -> false
  end
end
