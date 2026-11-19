defmodule Contexla.Estate.MixProject do
  use Mix.Project

  def project do
    [
      app: :contexla_estate,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Contexla.Estate.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:contexla_application_sdk, path: "../sdk"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 1.2"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.2"},
      {:oban, "~> 2.24"}
    ]
  end
end
