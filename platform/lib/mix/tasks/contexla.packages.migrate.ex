defmodule Mix.Tasks.Contexla.Platform.Packages.Migrate do
  use Mix.Task

  @shortdoc "Runs migrations owned by registered Application packages"

  @impl true
  def run([]) do
    previous = Application.get_env(:contexla, :start_registered_packages, true)
    Application.put_env(:contexla, :start_registered_packages, false)

    try do
      Mix.Task.run("app.start")

      case Contexla.Platform.Packages.Migrations.run_all() do
        :ok -> Mix.shell().info("Registered Application migrations are current.")
        {:error, reason} -> Mix.raise("Application migration failed: #{inspect(reason)}")
      end
    after
      Application.put_env(:contexla, :start_registered_packages, previous)
    end
  end

  def run(_args) do
    Mix.raise("usage: mix contexla.platform.packages.migrate")
  end
end
