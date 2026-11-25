defmodule Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource do
  @moduledoc """
  Deterministic external HTTP source simulator for Application acceptance tests.

  This simulator belongs to Content Integrity Monitor's test system. It is not
  an installable Connector and is not included in production Application builds.
  """

  use Supervisor

  alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl true
  def init(options) do
    port = Keyword.get(options, :port, 4_205)

    children = [
      ExternalHttpSource.State,
      {Bandit, plug: ExternalHttpSource.Router, scheme: :http, port: port}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
