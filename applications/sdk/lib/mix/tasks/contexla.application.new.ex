defmodule Mix.Tasks.Contexla.Application.New do
  use Mix.Task

  @shortdoc "Creates an independent Contexla Application project"
  @switches [module: :string, id: :string, name: :string]
  @templates ~w(
    .formatter.exs
    .gitignore
    README.md
    contexla-application.json
    mix.exs
    lib/application.ex
    lib/application_otp.ex
    lib/new_live.ex
    lib/overview_live.ex
    lib/collection_live.ex
    lib/settings_live.ex
    test/application_test.exs
    test/test_helper.exs
  )

  @impl true
  def run(args) do
    {options, remaining, invalid} = OptionParser.parse(args, strict: @switches)

    case {remaining, invalid, options[:module]} do
      {[path], [], module} when is_binary(module) -> generate!(path, options)
      _ -> Mix.raise(usage())
    end
  end

  defp generate!(path, options) do
    target = Path.expand(path)
    ensure_empty_target!(target)

    project = target |> Path.basename() |> Macro.underscore()
    validate_project!(project)

    module = options[:module]
    validate_module!(module)

    name = options[:name] || humanize(project)
    id = options[:id] || "com.example.application.#{String.replace(project, "_", "-")}"
    sdk_root = Path.expand("../../..", __DIR__)
    ui_root = Path.expand("../../ui/contexla_ui", sdk_root)

    binding = [
      project: project,
      module: module,
      web_module: module <> "Web",
      name: name,
      id: id,
      sdk_path: dependency_path(sdk_root, target),
      ui_path: dependency_path(ui_root, target)
    ]

    File.mkdir_p!(target)

    Enum.each(@templates, fn relative_path ->
      source = Path.join(template_root(), relative_path <> ".eex")
      destination = Path.join(target, relative_path)
      File.mkdir_p!(Path.dirname(destination))

      content =
        source
        |> EEx.eval_file(binding)
        |> format_source(relative_path)

      File.write!(destination, content)
    end)

    Mix.shell().info("Created independent Contexla Application at #{target}")
    Mix.shell().info("Next: cd #{target} && mix deps.get && mix test")
  end

  defp ensure_empty_target!(target) do
    if File.dir?(target) and File.ls!(target) != [] do
      Mix.raise("target directory is not empty: #{target}")
    end

    if File.exists?(target) and not File.dir?(target) do
      Mix.raise("target is not a directory: #{target}")
    end
  end

  defp validate_project!(project) do
    unless project =~ ~r/^[a-z][a-z0-9_]*$/ do
      Mix.raise("target directory name must produce a valid snake_case OTP Application name")
    end
  end

  defp validate_module!(module) do
    unless module =~ ~r/^[A-Z][A-Za-z0-9]*(\.[A-Z][A-Za-z0-9]*)*$/ do
      Mix.raise("--module must be an Elixir module name such as Acme.ContentAudit")
    end
  end

  defp humanize(project) do
    project
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp dependency_path(source, target) do
    source
    |> Path.relative_to(target)
    |> String.replace("\\", "/")
  end

  defp template_root do
    Application.app_dir(:contexla_application_sdk, "priv/templates/application")
  end

  defp format_source(content, path) do
    if Path.extname(path) in [".ex", ".exs"] do
      (content |> Code.format_string!() |> IO.iodata_to_binary()) <> "\n"
    else
      content
    end
  end

  defp usage do
    "usage: mix contexla.application.new PATH --module MODULE [--id ID] [--name NAME]"
  end
end
