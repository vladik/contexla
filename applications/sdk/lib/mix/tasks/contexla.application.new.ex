defmodule Mix.Tasks.Contexla.Application.New do
  use Mix.Task

  @shortdoc "Creates an independent Contexla Application project"
  @switches [id: :string, name: :string]
  @templates ~w(
    .formatter.exs
    .gitignore
    README.md
    contexla-application.json
    mix.exs
    lib/package.ex
    lib/application.ex
    lib/web/new_live.ex
    lib/web/overview_live.ex
    lib/web/collection_live.ex
    lib/web/settings_live.ex
    test/package_test.exs
    test/test_helper.exs
  )

  @impl true
  def run(args) do
    {options, remaining, invalid} = OptionParser.parse(args, strict: @switches)

    case {remaining, invalid} do
      {[path], []} -> generate!(path, options)
      _ -> Mix.raise(usage())
    end
  end

  defp generate!(path, options) do
    target = Path.expand(path)
    ensure_empty_target!(target)

    project = target |> Path.basename() |> Macro.underscore()
    validate_project!(project)

    module = "Contexla.Applications." <> Macro.camelize(project)

    name = options[:name] || humanize(project)
    id = options[:id] || "com.example.application.#{String.replace(project, "_", "-")}"
    sdk_root = Path.expand("../../..", __DIR__)
    ui_root = Path.expand("../../ui/contexla_ui", sdk_root)

    binding = [
      project: project,
      module: module,
      package_module: module <> ".Package",
      web_module: module <> ".Web",
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

  defp humanize(project) do
    project
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp dependency_path(source, target) do
    source
    |> Path.expand()
    |> normalize_drive()
    |> Path.relative_to(target |> Path.expand() |> normalize_drive(), force: true)
    |> String.replace("\\", "/")
  end

  defp normalize_drive(<<drive::binary-size(1), ":", rest::binary>>),
    do: String.downcase(drive) <> ":" <> rest

  defp normalize_drive(path), do: path

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
    "usage: mix contexla.application.new PATH [--id ID] [--name NAME]"
  end
end
