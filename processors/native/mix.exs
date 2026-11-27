defmodule Contexla.Processors.Native.MixProject do
  use Mix.Project

  def project do
    [
      app: :contexla_processors_native,
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
      {:contexla_capability_sdk, path: "../../capabilities/sdk"},
      {:contexla_capabilities_bundled, path: "../../capabilities/bundled"},
      {:floki, "~> 0.37"},
      {:jason, "~> 1.4"}
    ]
  end
end
