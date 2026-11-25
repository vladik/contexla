defmodule Mix.Tasks.Contexla.Application.Package do
  use Mix.Task

  @shortdoc "Builds a deterministic .contexla-app package"
  @switches [manifest: :string, output: :string]

  @impl true
  def run(args) do
    Mix.Task.run("compile")
    {options, remaining, invalid} = OptionParser.parse(args, strict: @switches)

    if remaining != [] or invalid != [] do
      Mix.raise("usage: mix contexla.application.package [--manifest PATH] [--output PATH]")
    end

    project = Mix.Project.config()
    manifest = options[:manifest] || "contexla-application.json"
    application = project |> Keyword.fetch!(:app) |> Atom.to_string()
    version = Keyword.fetch!(project, :version)

    output =
      options[:output] ||
        Path.join([
          Mix.Project.build_path(),
          "contexla",
          "#{application}-#{version}.contexla-app"
        ])

    case Contexla.Applications.Sdk.PackageBuilder.build(
           manifest,
           Mix.Project.app_path(),
           output
         ) do
      {:ok, result} ->
        Mix.shell().info("Built #{result.path}")
        Mix.shell().info("SHA-256 #{result.digest}")

      {:error, reason} ->
        Mix.raise("could not build package: #{inspect(reason)}")
    end
  end
end
