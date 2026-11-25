defmodule Contexla.Tools.Bundled.MixProject do
  use Mix.Project

  def project do
    [
      app: :contexla_tools_bundled,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:contexla_tool_sdk, path: "../sdk"},
        {:floki, "~> 0.38.0"}
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
