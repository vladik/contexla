defmodule Contexla.Drupal.MixProject do
  use Mix.Project

  def project do
    [
      app: :contexla_drupal,
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
      mod: {Contexla.Drupal.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:contexla_integration_sdk, path: "../sdk"},
      {:jason, "~> 1.4"}
    ]
  end
end
