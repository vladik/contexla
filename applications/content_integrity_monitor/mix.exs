defmodule Contexla.Applications.ContentIntegrityMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :content_integrity_monitor,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Contexla.Applications.ContentIntegrityMonitor.Application, []}
    ]
  end

  defp deps do
    [
      {:contexla_application_sdk, path: "../sdk"},
      {:contexla_ui, path: "../../ui/contexla_ui"},
      {:ecto_sql, "~> 3.14"},
      {:postgrex, ">= 0.0.0"},
      {:oban, "~> 2.24"},
      {:req, "~> 0.7"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.15", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_environment), do: ["lib"]
end
