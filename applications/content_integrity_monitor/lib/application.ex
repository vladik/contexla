defmodule Contexla.Applications.ContentIntegrityMonitor.Application do
  @moduledoc false
  use Application

  @simulator_port 4205

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :dev do
        alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource

        if port_available?(@simulator_port) do
          [{ExternalHttpSource, [port: @simulator_port]}]
        else
          require Logger
          Logger.warning("Simulator port #{@simulator_port} already in use — skipping simulator startup.")
          []
        end
      else
        []
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Contexla.Applications.ContentIntegrityMonitor.Supervisor
    )
  end

  defp port_available?(port) do
    case :gen_tcp.listen(port, []) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, :eaddrinuse} ->
        false
    end
  end
end
