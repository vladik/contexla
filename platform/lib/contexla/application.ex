defmodule Contexla.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ContexlaWeb.Telemetry,
      Contexla.Repo,
      {DNSCluster, query: Application.get_env(:contexla, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Contexla.PubSub},
      Contexla.Packages.Registry,
      Contexla.CapabilityRuntime.Registry,
      {Oban, Application.fetch_env!(:contexla, Oban)},
      # Start to serve requests, typically the last entry
      ContexlaWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Contexla.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ContexlaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
