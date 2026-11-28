defmodule Contexla.Tools.Bundled.ParseComposerDependencies do
  @moduledoc "Native Tool that returns normalized Composer dependency facts."

  @behaviour Contexla.Tools.Sdk.NativeTool

  @impl true
  def execute(%{"composer_json" => composer_json, "composer_lock" => composer_lock}, _context)
      when is_map(composer_json) and is_map(composer_lock) do
    direct = dependency_names(composer_json["require"])
    direct_dev = dependency_names(composer_json["require-dev"])

    dependencies =
      composer_lock
      |> locked_packages()
      |> Enum.map(fn {package, development?} ->
        name = package["name"]

        %{
          "name" => name,
          "version" => package["version"],
          "type" => package["type"],
          "development" => development?,
          "direct" => MapSet.member?(if(development?, do: direct_dev, else: direct), name)
        }
      end)
      |> Enum.sort_by(& &1["name"])

    {:ok, %{"dependencies" => dependencies}}
  end

  def execute(_input, _context), do: {:error, :invalid_composer_input}

  defp dependency_names(value) when is_map(value), do: value |> Map.keys() |> MapSet.new()
  defp dependency_names(_value), do: MapSet.new()

  defp locked_packages(lock) do
    Enum.map(lock["packages"] || [], &{&1, false}) ++
      Enum.map(lock["packages-dev"] || [], &{&1, true})
  end
end
