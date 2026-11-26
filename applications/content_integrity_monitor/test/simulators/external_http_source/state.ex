defmodule Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource.State do
  @moduledoc false

  use Agent

  def start_link(_options), do: Agent.start_link(fn -> :healthy end, name: __MODULE__)

  def mode, do: Agent.get(__MODULE__, & &1)

  def set_mode(mode) when mode in [:healthy, :pending, :overdue, :unavailable] do
    Agent.update(__MODULE__, fn _current -> mode end)
  end
end
