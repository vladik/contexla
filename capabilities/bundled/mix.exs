defmodule Contexla.Capabilities.Bundled.MixProject do
  use Mix.Project

  def project do
    [
      app: :contexla_capabilities_bundled,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:contexla_capability_sdk, path: "../sdk"}
    ]
  end
end
