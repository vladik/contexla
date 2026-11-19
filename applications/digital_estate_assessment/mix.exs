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
      {:contexla_application_sdk, path: "../sdk"}
    ]
  end
end
